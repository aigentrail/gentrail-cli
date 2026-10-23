# Gentrail

Connect Claude Code or Codex to your organization’s Gentrail instance with the
desktop setup application. The CLI also runs Gentrail locally and deploys it to
your AWS account. Both downloads come from this repository.

## Desktop setup

Choose the download for your computer:

| Platform | Downloads                                                                                                                                                                                                                                                                          |
| -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Windows  | [Most PCs (x64)](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-windows-amd64.exe) · [ARM64](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-windows-arm64.exe) |
| macOS    | [Apple Silicon](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-darwin-arm64.zip) · [Intel](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-darwin-amd64.zip)    |
| Linux    | [x64](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-linux-amd64.tar.gz) · [ARM64](https://github.com/aigentrail/gentrail-cli/releases/download/desktop-v0.11.2/gentrail-setup-linux-arm64.tar.gz)          |

1. Open the Windows installer, or extract the macOS/Linux archive and open
   Gentrail Setup. Installation is for your user account.
2. Select Claude Code or Codex and choose one project or all your projects.
3. Enter your organization’s Gentrail server URL, leave the API key blank, and
   choose **Continue**. Sign in to Gentrail in the browser and approve the
   computer after checking that the approval code matches the wizard.
4. Return to the wizard and choose **Continue**. Review the permissions and
   trace collector, test the connection, and install the hooks.
5. Restart your coding agent, review or trust the Gentrail hooks, and try a tool call.

Browser approval creates a key scoped to this agent and saves it privately on
your computer. You do not need to copy a key. Existing agent API keys can also
be entered manually; they are different from license keys. An unfinished
connection is removed when you cancel setup. To revoke an installed connection,
open **Integrations → Your computers** in Gentrail and remove that computer.

When your company already runs Gentrail, use that instance. You do not need to
start a local server or deploy another AWS stack.

To add an employee, an organization administrator opens **Integrations → Team
invitations**, enters their work email, and shares the invitation privately.
The employee follows the link, chooses a password, and completes their profile.
Profile setup then opens **Your computers** with instructions for connecting
Gentrail Setup to the existing company instance.
Invitations expire after 72 hours, work once, and can be revoked from the same
page. New accounts are members. Invitation links are shown only when created;
create a new invitation if the original link is lost.

These preview applications are unsigned. Your operating system may display a
warning when you open them. Checksums for every download are included in the
release’s `SHA256SUMS` file.

Run Gentrail Setup again to update or disconnect an agent. Disconnect every
agent before choosing Remove application; saved data is retained.

## CLI installation

On macOS or Linux:

```bash
curl -LsSf https://gentrail.ai/install.sh | sh
gentrail
```

On Windows, paste this into PowerShell:

```powershell
irm https://gentrail.ai/install.ps1 | iex
gentrail
```

Run the same install command to update.

For manual installation, binaries and checksums are on
[Releases](https://github.com/aigentrail/gentrail-cli/releases).

The CLI menu handles setup, licenses, agent connections, and AWS deployments.
You don't need to clone this repo.

## Run locally

Choose **Open local workspace**, then **Start Gentrail**. On first launch, request a free license, paste an
existing key, or continue to set up your license in the browser.
Agent activity requires a license.
The dashboard opens in your browser once ready;
its address is also printed in the terminal.

The menu stays available while Gentrail runs. Connect agents, view logs, or open
the dashboard from the local workspace. Quitting the CLI stops the instance it
started; your data stays in `~/.gentrail`. If Gentrail is already running in
another terminal, the workspace connects to it and leaves it running on exit.
To run the service directly, use `gentrail serve`.
Add `--export-to <dir or s3://bucket/prefix>` to also write traces and tool
calls as Parquet for DuckDB or a shared bucket.

The CLI remembers your last workspace. Local opens its status screen on the
next launch. AWS remembers the stack, region, profile, and connection addresses;
a project's `gentrail.toml` takes precedence.

Set `GENTRAIL_NO_BROWSER=1` to skip opening the browser. Scripted runs do not
open it. Set `GENTRAIL_NO_PROGRESS=1` to hide installer download progress.

## Connect an agent

Choose **Connect an agent** in the CLI. If you started with `gentrail serve`,
open `gentrail` in another terminal first. Select
Claude Code or Codex, then choose this project or all your projects.

For local use, setup finds your API key automatically. For AWS, choose
**Connect an agent** from the AWS workspace. The URLs are filled in; get an API
key from **Integrations** in the dashboard.

After setup, restart Claude Code and check `/hooks`. In the Codex desktop app,
open **Settings → Hooks**, select your project, and review and trust the Gentrail
hooks. In Codex CLI, use `/hooks`. Ask the agent to read a small file. The CLI waits
for Gentrail to store that hook's policy check, then offers **View activity**.
Registration and connection tests do not count as a real policy check.

You can leave this screen and return later. Choose the same agent and scope
to verify the saved setup without changing its settings. If no activity arrives,
check hook trust, project scope, and the saved connection.

Blocked calls are denied. Calls that need approval prompt in Claude Code and
are denied in Codex. Setup also lets you choose what happens when Gentrail
cannot be reached. Run setup again to update or remove the hook.

Hooks report checks before execution, not tool results or model usage. For
those, use the [SDK](https://github.com/aigentrail/sdk) with an API key from
**Integrations** and your Gentrail OTLP endpoint. Locally, that endpoint is
`http://127.0.0.1:4318`. API keys and license keys are separate.
To print SDK environment commands, start with `gentrail serve --sdk-env`.
These commands include your API key; keep them private.

## Deploy to AWS

Configure AWS credentials for the target account, then choose **Deploy Gentrail**.
Setup checks your AWS credentials and connection tools, then shows the account,
plan, and cost estimate before creating resources.

| Deployment | Runs on               | Storage                                                                    |
| ---------- | --------------------- | -------------------------------------------------------------------------- |
| Evaluation | One EC2 node with k3s | On the node; replacing or deleting it loses the data                       |
| Production | EKS                   | RDS, DynamoDB, and S3, with KMS encryption and S3 Object Lock for evidence |

Your AWS principal needs the [deployment permissions](iac/cfn/deploy-policy.json).
AWS charges for the resources in your account.

Setup opens the AWS workspace when installation finishes. Choose
**Open AWS workspace** to reconnect later. This needs `aws` and `kubectl`;
Evaluation also needs the AWS Session Manager plugin. For Production, your
principal needs EKS access. The principal that installed it already has access.

Keep the CLI open while using the connection. The workspace has agent setup,
logs, and a reconnect action that does not repeat deployment. Quitting disconnects
your machine; AWS resources keep running.
Both AWS deployments have **no dashboard login**. Use the CLI tunnel or keep
access limited to your network. Production endpoints are private by default.

### Export traces

Production can copy traces and tool calls into an S3 bucket you own, as
Parquet partitioned by org, date, and hour, for Athena, BigQuery, Snowflake, or
DuckDB. Answer **Export bucket** in the setup questions, or set
`data.export_bucket` in `gentrail.toml`. Each 5-minute window arrives about 15
minutes after it closes, and the first run backfills the last 24 hours.

The bucket can live in another account. Its bucket policy must allow
`s3:PutObject` under the export prefix for the stack's exporter role (the
`ExporterIrsaRole` resource), and a bucket encrypted with your own KMS key must
let that role call `kms:GenerateDataKey`.

### Scripts

Setup saves deployment settings in `gentrail.toml`, without the license key:

```bash
gentrail install --plan gentrail.toml --yes
```

Use `GENTRAIL_LICENSE_JWT` for a license key or JWT file path. Keep keys out of
version control. See `gentrail <command> --help` for flags; use the same stack
name and region when returning to a deployment.

### Remove a deployment

Choose **Remove deployment**, or run `gentrail teardown`.

Evaluation deletes the node and its data. Production deletes EKS, RDS, and
stack-owned load balancers, taking a final RDS snapshot. DynamoDB tables, S3
buckets, and the KMS key remain and can still incur charges. Delete retained
resources separately when no longer needed; retained table names can prevent
reusing the same stack name.

## What's in this repo

The [Helm chart](charts/gentrail), [CloudFormation templates](iac/cfn), and
[initialization files](iac/init). CLI binaries ship with releases; the chart
pulls public container images. Application source is not included.

## Tokenization encryption keys

AWS installation creates a dedicated tokenization key and scoped permissions by
default. The key persists across release upgrades and is retained when the
CloudFormation stack is removed. Keep it while stored organization data keys
depend on it. Retained keys can continue to incur AWS charges.

To supply your own key, set the install plan's `data.pii_kms_key_arn` answer or
the CloudFormation `ExistingPiiTokenizationKeyArn` parameter. Its key policy must
permit the deployment's dashboard identity to generate and decrypt data keys
with the `gentrail:purpose=pii-tokenization` encryption context. Production uses
the dashboard IRSA role; the single-node evaluation appliance uses its instance
profile. The installer propagates the selected key and its region automatically.

An administrator enables Tokenize in the dashboard when the organization is
ready. The deployment key needs no manual ARN entry there. Existing organization
keys remain unchanged across upgrades, and changing the deployment default does
not repoint an organization's wrapped keys. Employees only connect to their
company dashboard; they do not configure encryption keys.
