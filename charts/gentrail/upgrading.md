# Upgrade a BYOC installation

An operator upgrades the application through Helm. Updating the CLI or changing
a CloudFormation `RepoBranch` parameter does not update the running application.
The commands below use Helm 3 and the default release and namespace, `gentrail`.
Adjust them if your installation uses different names.
For Helm 4, replace `--atomic` with `--rollback-on-failure` in the upgrade
command. Both versions support the readiness and job waits shown below.

## Before upgrading

Choose a published release and review its release notes and migration requirements.
Confirm that a recent database backup and any required storage backups are
available. Helm rollback restores application manifests; it does not reverse
database migrations or restore deleted data.

Use the installation's existing AWS account, region, database, storage, and
encryption keys. Application updates normally do not require recreating its
CloudFormation stack. Keep custom image references, enabled modules, identity
configuration, and external secret references in the reviewed deployment values.

## Access the cluster

For standard, open an AWS Session Manager session to the node identified by the
stack's `InstanceId` output. For example, from your workstation:

```sh
aws cloudformation describe-stacks --stack-name gentrail --region us-west-2 \
  --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' --output text
aws ssm start-session --target YOUR_INSTANCE_ID --region us-west-2
```

Use your own stack name, region, instance ID, and AWS profile. Inside that node
session, become root and select the existing k3s cluster:

```sh
sudo -i
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
```

For enterprise, use a workstation with Helm and `kubectl`, and configure access
to the existing EKS cluster:

```sh
aws eks update-kubeconfig --name YOUR_CLUSTER_NAME --region us-west-2
```

Check the target before changing anything:

```sh
kubectl config current-context
helm list --namespace gentrail
helm history gentrail --namespace gentrail
```

On standard, use `k3s kubectl` if `kubectl` is not on the node's path.

## Prepare the release and values

Work in a private directory. Saved Helm values can contain credentials and
license material. Record the current revision for recovery.

```sh
umask 077
mkdir gentrail-upgrade
cd gentrail-upgrade
TARGET_VERSION=v0.13.2
helm get values gentrail --namespace gentrail -o yaml > current-values.yaml
helm history gentrail --namespace gentrail > history-before.txt
git clone --depth 1 --branch "$TARGET_VERSION" \
  https://github.com/aigentrail/gentrail-cli.git release
```

Review `current-values.yaml` against the new chart defaults. Preserve your
installation-specific settings and remove options the target release no longer
supports. If the installation has no user-supplied values, use an empty YAML
mapping (`{}`) instead of `null`.

Create `upgrade-values.yaml` to select the target release. Replace the example
version if you chose another release:

```yaml
image:
  tag: v0.13.2
```

If `image.references` contains digest-pinned overrides, update each enabled
component to the target release's image digest. Digest overrides take precedence
over `image.tag`. Preserve custom registry authentication when using private
images. Do not mix a new chart with old application images by leaving overrides
unchanged.

## Apply and verify

```sh
helm upgrade gentrail ./release/charts/gentrail --namespace gentrail \
  --reset-values -f current-values.yaml -f upgrade-values.yaml \
  --atomic --wait --wait-for-jobs --timeout 15m
helm status gentrail --namespace gentrail
kubectl --namespace gentrail get pods
kubectl --namespace gentrail get jobs
```

The chart runs its database preflight and broker bootstrap where enabled. Check
that those jobs succeed as well as checking application readiness.
Verify the enabled applications, the installed image references, and a real
customer workflow: use an existing API key, read a stored policy or trace, and
send new activity through ingestion and evaluation. Check that the license,
authentication settings, and retained data are still available.

Publishing a release or updating the CLI does not perform these steps for you.

## Failure and rollback

`--atomic` attempts to roll back an unsuccessful application upgrade. Inspect
`helm history`, pod status, and failed job logs before retrying. A successful
rollback still needs the application and data checks above.

If a later check reveals a problem, and the previous application version is
compatible with the current database schema, choose the previous known-good
revision from Helm history:

```sh
helm rollback gentrail PREVIOUS_REVISION --namespace gentrail --wait --timeout 15m
```

If a migration prevents running the previous version, follow the release's data
recovery procedure instead. Preserve the database and storage while diagnosing;
teardown and reinstall are not rollback operations.
