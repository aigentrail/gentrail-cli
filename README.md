# Gentrail CLI

Run Gentrail locally or in your own AWS account. Check agent tool calls against
policies and see their activity in a dashboard. Your data stays on your machine
or in your AWS account.

## Install

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

The Windows installer chooses x64 or ARM64, verifies the download, and installs
into `%LOCALAPPDATA%\Gentrail\bin`. It adds that directory to your user PATH;
no administrator access is needed. Both installers show download progress.
Run the same command to update.

For manual installation, binaries and checksums are on
[Releases](https://github.com/aigentrail/gentrail-cli/releases).

The CLI menu handles setup, licenses, agent connections, and AWS deployments.
You don't need to clone this repo.

## Run locally

Choose **Manage license** to request a free license or save an existing key.
Then choose **Start Gentrail**. The dashboard opens in your browser once ready;
its address is also printed in the terminal.

Keep the terminal open while using Gentrail. Ctrl-C stops it; your data stays in
`~/.gentrail`. To start it directly next time, run `gentrail serve`.

Set `GENTRAIL_NO_BROWSER=1` to skip opening the browser. Scripted runs do not
open it. Set `GENTRAIL_NO_PROGRESS=1` to hide installer download progress.

## Connect an agent

In another terminal, run `gentrail` and choose **Connect an agent**. Select
Claude Code or Codex, then choose this project or all your projects.

For local use, setup finds your API key automatically. For AWS, enter the
dashboard and trace ingest URLs printed by **Open dashboard**, plus an API key
from **Integrations** in the dashboard.

After setup, restart Claude Code and check `/hooks`. In Codex, open `/hooks`
and trust the Gentrail hook. The agent appears in Gentrail after registration;
new tool calls report their policy checks and arguments.

Blocked calls are denied. Calls that need approval prompt in Claude Code and
are denied in Codex. Setup also lets you choose what happens when Gentrail
cannot be reached. Run setup again to update or remove the hook.

Hooks report checks before execution, not tool results or model usage. For
those, use the [SDK](https://github.com/aigentrail/sdk) with an API key from
**Integrations** and your Gentrail OTLP endpoint. Locally, that endpoint is
`http://127.0.0.1:4318`. API keys and license keys are separate.

## Deploy to AWS

Configure AWS credentials for the target account, then choose **Deploy Gentrail**.
Setup asks for a region, stack name, and deployment type, then shows the plan
and cost estimate before creating resources.

| Deployment | Runs on | Storage |
| --- | --- | --- |
| Evaluation | One EC2 node with k3s | On the node; replacing or deleting it loses the data |
| Production | EKS | RDS, DynamoDB, and S3, with KMS encryption and S3 Object Lock for evidence |

Your AWS principal needs the [deployment permissions](iac/cfn/deploy-policy.json).
AWS charges for the resources in your account.

Setup opens a dashboard connection when installation finishes. Choose
**Open dashboard** to reconnect later. This needs `aws` and `kubectl`;
Evaluation also needs the AWS Session Manager plugin. For Production, your
principal needs EKS access. The principal that installed it already has access.

Leave the connection running. Your browser opens when the dashboard is ready,
and the terminal prints a clickable link.
Both AWS deployments have **no dashboard login**. Use the CLI tunnel or keep
access limited to your network. Production endpoints are private by default.

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
