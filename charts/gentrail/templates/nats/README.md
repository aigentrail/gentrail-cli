# NATS event transport

NATS carries committed facts; SQL rows and transactional outboxes remain the
application authority. EVENTS retains events for one hour with a two-minute
publication duplicate window. Broker storage is not a replay archive.

## Service identity

Networked clients require TLS with the mounted CA and their own client.json
credential file. Authproxy, evaluator, dashboard and headless receive separate
Secrets. Operator bootstrap receives a separate credential, never application
credentials or cloud authority. Application pods do not receive the server key
or operator credential. Anonymous connections are supported only for loopback
development and test brokers, not network endpoints.

The allowlists in iac/nats.cue generate files/nats-permissions.json. They restrict
fact publication, reads from assigned consumers, acknowledgments and reply
inboxes. Each service uses its own _INBOX prefix so it cannot subscribe to replies
for another service. Application identities cannot create, modify or delete
streams or consumers. The operator may provision EVENTS but cannot read raw
business events. Broker permissions do not authenticate tenant IDs inside events;
shared multi-tenant services remain responsible for tenant isolation.

## Bootstrap and delivery

A normal revision-scoped bootstrap Job uses the evaluator image with
--bootstrap-broker before application workers can bind to their consumers. It is
not a post-install Helm hook, which would deadlock installs using --wait. The Job
creates or updates EVENTS and five durable consumers: evaluator,
operation-evaluator, trace-outbox-acks, operation-outbox-acks and
compliance-exceptions. Runtime clients verify the stream and bind to provisioned
consumers without management permissions.

Dashboard refresh hints use explicit live subscriptions for every replica. A
bounded 4096-entry window suppresses recent publication IDs for two minutes.
Overflow, reconnect gaps and duplicate hints are reconciled from SQL; this cache
cannot determine business state. Compliance processing remains durable and
explicitly acknowledged. Broker reconnects restore live subscriptions.

## Credentials and rotation

Helm preserves the current CA, server certificate and role passwords through
Secret lookup. Increment nats.credentialRevision and perform a coordinated Helm
upgrade to rotate them. Secret checksums roll the broker and application pods;
clients reread password files on reconnect. CA changes require the pod rollout,
not just a password-file update. Server certificates last one year; rotate before
expiry. Single-node rotation can interrupt delivery while pods reconnect. Durable
SQL outboxes retain unacknowledged work for retry.

Server configuration is a Secret. Monitoring binds to loopback and is not exposed
by either Service. Cluster peers use TLS, certificate verification and a separate
cluster password; the peer port accepts traffic only from broker pods. The
bootstrap pod has no Kubernetes service-account token.

The compose-backed gentrail local command generates private certificate and role
files before startup and preserves them on later starts. Each container mounts
only its role directory. Stop the stack before replacing these files for local
rotation. Native gentrail serve provisions its embedded loopback broker and
does not require an external NATS deployment. The loopback integration
harness invokes operator bootstrap before starting services.

## Storage and recovery

nats.replicas sets broker and stream replication together. nats.storage selects
ephemeral or persistent storage; ordinary upgrades reject changing the storage
kind of an existing StatefulSet. Persistent claims survive broker restarts.
Recovery reads retained SQL rows and retries SQL outboxes. Restore, capacity and
multi-node failover qualification remain separate deployment checks.
