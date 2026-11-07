# Gentrail

Gentrail provides AI agent governance and compliance monitoring. Use the CLI to
connect Claude Code or Codex to an existing Gentrail instance, run locally, or
deploy into your AWS account.

## Install the CLI

On macOS or Linux:

```sh
curl -LsSf https://gentrail.ai/install.sh | sh
gentrail version
gentrail
```

On Windows, run in PowerShell:

```powershell
irm https://gentrail.ai/install.ps1 | iex
gentrail version
gentrail
```

The installers download the latest stable CLI and verify its SHA256 checksum.
Linux, macOS, and Windows binaries are available for AMD64 and ARM64 on the
[release page](https://github.com/aigentrail/gentrail-cli/releases).
You do not need to clone this repository.

## Connect a coding agent

If your organization already runs Gentrail, connect to that instance.
Open `gentrail`, choose **Connect an agent**, select Claude Code or Codex, and
choose the project or all-projects scope. For an AWS workspace, the server
addresses are filled in. For local use, setup finds the local API key.

Follow setup to configure the connection and permissions. Restart the coding
agent, review and trust the hooks, then ask it to read a small file. Setup waits
for a stored policy check before offering **View activity**. Registration and
connection tests alone do not count as a policy check.

In Claude Code or Codex CLI, use `/hooks` to inspect installed hooks. In Codex
desktop, open **Settings → Hooks** and select your project. Run connection setup
again to review, change, or remove the saved settings.

Hooks govern tool calls. For application traces and model usage, use the
[SDK](https://github.com/aigentrail/sdk) with your instance's OTLP endpoint and
an API key from **Integrations**. API keys and license keys are separate.

## Run locally

Open `gentrail`, choose **Open local workspace**, then **Start Gentrail**, or run:

```sh
gentrail serve
```

The native runtime needs no container engine. By default, the dashboard listens
on `http://127.0.0.1:7331` and OTLP ingestion on `http://127.0.0.1:4318`.
Local data and the license live in `~/.gentrail`, unless you select another data
directory. Agent activity requires a license; setup can request or install one.

Stopping the local runtime preserves its data. Reuse the same data directory
when starting it again. `GENTRAIL_NO_BROWSER=1` disables automatic browser opening.

Use `gentrail serve --sdk-env` to print SDK environment commands, including your
API key. Keep that output private. `--export-to <directory or s3://bucket/prefix>`
also exports closed trace windows as Parquet.

## Deploy to AWS

Configure AWS credentials for the target account, then choose **Deploy Gentrail**
in the CLI. Review the account, region, resources, and installation profile
before confirming.

| Profile | Runtime | Storage |
| --- | --- | --- |
| `local` | Native runtime on your computer | SQLite and local files; no AWS resources |
| `standard` | One ARM64 k3s node, initially `t4g.medium` | Private RDS PostgreSQL, persistent node-local NATS, S3 evidence and trace archives |
| `enterprise` | EKS | Managed PostgreSQL, S3 evidence and archives, KMS, and selected availability settings |

Standard creates no EKS cluster, NAT gateway, or load balancer. It shares a
single-node application and broker failure domain. Neither a profile name nor a
license plan is a capacity or availability guarantee. AWS bills the resources
in your account, including retained storage and snapshots.

Your AWS principal needs the [deployment permissions](iac/cfn/deploy-policy.json).
For scripted installation, save your settings in `gentrail.toml`, then run:

```sh
gentrail install --plan gentrail.toml --yes
```

Use `GENTRAIL_LICENSE_JWT` for a license JWT or its file path. Keep credentials
and license keys out of version control.

Use **Open AWS workspace** or `gentrail connect` to reconnect. Connection needs
the AWS CLI and `kubectl`; standard also needs the AWS Session Manager plugin.
Enterprise requires access to its EKS cluster. Closing the connection leaves
the AWS deployment running. Keep endpoints private unless you deliberately
configure external access. Application sign-in follows the installation's
license and authentication configuration.

## Updates

### Update the CLI

Stop any local Gentrail runtime and close the CLI, then rerun the installation
command above for your operating system. The installer replaces the executable;
it does not delete saved workspaces, connections, licenses, or local data.
If you used `GENTRAIL_BIN_DIR`, use the same directory when updating.

Confirm the installed version with `gentrail version`, then reopen Gentrail and
restart your coding agents. If you manage a standalone `gentrail-hook` binary,
replace it with the matching release asset as well; the CLI installer updates
the CLI executable only.

To select a specific CLI release on macOS or Linux:

```sh
curl -LsSf https://gentrail.ai/install.sh | GENTRAIL_VERSION=v0.13.1 sh
```

In PowerShell:

```powershell
$env:GENTRAIL_VERSION = 'v0.13.1'
irm https://gentrail.ai/install.ps1 | iex
Remove-Item Env:GENTRAIL_VERSION
```

Omit `GENTRAIL_VERSION` to use the latest stable release.

### Update a local runtime

Back up its data with `gentrail snapshot` before changing versions. If you use
a custom data directory, pass the same `--data-dir` to snapshot and serve.
Update the CLI, then restart `gentrail serve` with your existing data directory.
The local runtime is included in the CLI binary.

### Update an AWS installation

Updating the CLI does not upgrade an existing AWS installation. Publishing a
release does not automatically change customer deployments either.

An operator applies the target release's Helm chart and matching images using
the installation's saved settings. Follow the [BYOC upgrade guide](charts/gentrail/upgrading.md)
for preflight checks, configuration preservation, verification, and rollback.
There is currently no `gentrail upgrade` command. Rerunning `gentrail install`
on an existing stack is not an application upgrade procedure.

### Desktop setup

Native desktop installers have a separate release cadence. CLI releases do not
require matching GUI packages. Use the CLI instructions above unless a desktop
installer is explicitly available for your platform.

## Remove an AWS deployment

Choose **Remove deployment** or run `gentrail teardown` with the correct stack,
region, and AWS profile. Standard removes its node and RDS instance; enterprise
also removes its EKS cluster and stack-owned load balancers.

Both retain a final database snapshot, S3 storage, and the tokenization KMS key.
Enterprise can also retain log and template-staging buckets. Retained resources
remain billable and need separate lifecycle management. Keep encryption keys
while retained organization data depends on them.

## Repository contents

This repository distributes the [Helm chart](charts/gentrail),
[CloudFormation templates](iac/cfn), and release binaries. The chart pulls public
container images. Application source is not included.

Use `gentrail <command> --help` for command flags.
