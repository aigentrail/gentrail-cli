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

**CLI:** stop any local runtime and close Gentrail, then rerun the installer
above. Saved data and connections are preserved. Reuse `GENTRAIL_BIN_DIR` if you
chose a custom install directory. Run `gentrail version` to check the result,
then reopen Gentrail and restart your coding agents. Update any separately
managed `gentrail-hook` binary from the same release.

**Local runtime:** back up with `gentrail snapshot`, update the CLI, then restart
`gentrail serve` using the same data directory. For custom storage, pass the same
`--data-dir` to snapshot and serve.

**AWS installation:** an operator applies the new Helm chart and matching images.
Follow the [BYOC upgrade guide](charts/gentrail/upgrading.md) to preserve settings,
verify the deployment, and handle rollback. Updating the CLI or rerunning
`gentrail install` does not upgrade an existing AWS application. There is no
`gentrail upgrade` command yet.

## More

- [Helm chart](charts/gentrail)
- [CloudFormation templates](iac/cfn) and [deployment permissions](iac/cfn/deploy-policy.json)
- `gentrail <command> --help`

This repository distributes binaries and deployment artifacts. Application source
is not included.
