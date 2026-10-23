# NATS event transport

The chart deploys NATS JetStream for dashboard, authproxy and evaluator events.
The former SNS/SQS pipeline and EC2/systemd migration proposals are retired;
there is no transport-selection flag or parallel SNS ingestion path.

The shared Go event-stream contract owns stream `EVENTS`, subject prefix `events.`, a one-hour maximum event age and
a two-minute duplicate window. Authproxy publishes `trace.ingested`; the evaluator
publishes `violation.created` and `agent.updated` for dashboard fan-out.
DynamoDB remains the durable activity store. Expired broker messages are not a
replay archive, and broker persistence alone does not certify complete recovery.

Live trace deliveries share a twenty-second processing deadline across storage,
evaluation and publication. Shutdown lets in-flight deliveries drain within that
budget. Failed or timed-out evaluations request redelivery instead of acknowledging
success; the consumer retains its sixty-second acknowledgement wait.

Enabled evaluator recovery sweeps resume an existing per-tenant cursor without
truncating old progress to the stream's retention window. Each sweep processes
at most 500 traces per tenant and stays five minutes behind live traffic. Range
reads use strong consistency and stop after eight queries of at most 250 evaluated
items, within a ten-second read budget. Progress comes from the scanned range,
including filtered tool rows, and is saved only after returned traces evaluate
successfully. A bounded partial read resumes next sweep instead of skipping to
the time horizon. A tenant
without a cursor still bootstraps from the previous hour; this is not a full
historical rebuild. Recovery reads retained DynamoDB rows, not cold archives.

Each tenant's recovery evaluation shares the live twenty-second processing
budget, including cursor reads, tool and rule loads, evaluation and writes.
The shorter ten-second range-read budget remains inside it. Canceled or timed-out
work never advances past an incomplete trace; cancellation also stops the sweep
before it starts another tenant. Tenant discovery has its own twenty-second
budget before these per-tenant budgets. Rule-cache waits honor cancellation;
canceled refreshes do not report a successful stale catalog. Transient storage
errors can still use the last cached catalog.

Recovery reserves the final two seconds of each tenant budget for one cursor
checkpoint. A failed batch can checkpoint its contiguous prefix of durable
complete or partial evaluations, so the next sweep resumes at the first failed
trace. Success after a gap cannot move the checkpoint past that gap. Caller
cancellation prevents checkpointing, and a process crash safely repeats work
from the previous durable cursor. No per-trace checkpoint writes are added.

New evaluator findings and their pending `violation.created` notifications are
committed in one DynamoDB transaction. Pending rows use `OUTBOX#VIOLATIONS` in
the existing violations table, outside tenant rows and indexes. The evaluator
flushes after new findings and polls every two seconds, independently of rules,
licenses and recovery cursors. Each sweep reads at most 100 rows within a
20-second budget. Each sweep groups notifications by tenant and deduplicates trace IDs, so several
findings on one trace do not repeat the compliance lookup for every finding.
A row is deleted only after JetStream accepts its event;
publication or cleanup failure retains it for retry. Duplicate delivery is
expected and compliance exception identities remain idempotent.

Apply the evaluator's `DeleteItem` IAM grant before rolling out this writer.
No table or index migration is required. Previously stored findings do not gain
pending rows retroactively; stream retention still bounds downstream recovery
after a notification has been accepted and its outbox row removed.

## Replicas

`nats.replicas` sets the StatefulSet size and `NATS_STREAM_REPLICAS` for the
services. The default is one; a three-node cluster uses three stream replicas.
Keep the broker count and stream replication consistent. An unset
`NATS_STREAM_REPLICAS` uses one replica for local defaults; malformed, zero or
negative explicit values fail before publishers can update the stream. A shared chart does not
by itself establish deployment parity, availability or tested failover.

## Storage

`nats.storage` declares `ephemeral` or `persistent`. Both use `nats.jetstreamSize`;
persistent storage creates the `data` volume claim template and retains its
contents across pod restarts. Our production CUE stage declares persistent
storage; dev declares ephemeral storage.

Upgrades read the existing StatefulSet and reject a change between these storage
types before applying resources. There is no broker recreation or volume deletion
hook. An existing persistent installation must keep `nats.storage=persistent`.
Storage transitions require a separate migration with retention and recovery
proof; an ordinary application upgrade cannot perform one.
