# Gentrail

AI agent governance and compliance monitoring. Connect coding agents to an
existing Gentrail instance, run locally, or deploy into your AWS account.

## Install

macOS or Linux:

```sh
curl -LsSf https://gentrail.ai/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://gentrail.ai/install.ps1 | iex
```

The installers download the latest stable CLI and verify its checksum.
[Manual downloads](https://github.com/aigentrail/gentrail-cli/releases) support
AMD64 and ARM64 on all three platforms. Native GUI releases are separate.

## Get started

Run `gentrail` to open the menu:

- **Connect an agent:** choose Claude Code or Codex and your project scope.
  Restart the agent and trust the installed hooks.
- **Open local workspace:** start Gentrail on your computer. You can also run
  `gentrail serve` directly, with no container engine.
- **Deploy Gentrail:** configure AWS credentials, choose a profile, and review
  the target account and resources before confirming.

| Profile | Runtime | Storage |
| --- | --- | --- |
| `local` | Your computer | SQLite and local files |
| `standard` | One ARM64 k3s node | Private RDS PostgreSQL, persistent NATS, S3 |
| `enterprise` | EKS | Managed PostgreSQL, S3, KMS |

Local data stays in `~/.gentrail` unless configured otherwise. Agent activity
requires a license. Application traces and model usage use the
[SDK](https://github.com/aigentrail/sdk); API keys and license keys are separate.

Use `gentrail connect` to reconnect to AWS, or `gentrail teardown` to remove a
deployment. Retained database snapshots, S3 storage, and encryption keys remain
billable after teardown.

## Updates

**AWS deployment:** review and apply the latest stable application release:

```sh
gentrail update --check
gentrail update
```

Uses your saved AWS workspace. Select another deployment with `--stack`,
`--region`, and `--profile`, or a specific release with `--version vX.Y.Z`.
Settings, storage, and keys are preserved. Services restart briefly; failed
upgrades attempt an application rollback. Database migrations are not reversed.
The command prints an operation ID and recovery instructions if interrupted.
Standard updates continue in AWS; keep the CLI open for Enterprise updates.

If your CLI does not recognize `update`, rerun the installer above first.
Updating the CLI alone does not update an AWS deployment.

**Local runtime:** back up with `gentrail snapshot`, update the CLI, then restart
`gentrail serve` using the same data directory. For custom storage, pass the same
`--data-dir` to snapshot and serve.

See the [operator upgrade guide](charts/gentrail/upgrading.md) for manual Helm
operations and database recovery.

## More

- [Helm chart](charts/gentrail)
- [CloudFormation templates](iac/cfn) and [deployment permissions](iac/cfn/deploy-policy.json)
- `gentrail <command> --help`

This repository distributes binaries and deployment artifacts. Application source
is not included.
