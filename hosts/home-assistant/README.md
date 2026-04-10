# Home Assistant

## First-time install

`install-ha.sh` runs from macOS. It clones or updates the repo on the remote host, copies your secrets file, and runs the Helm deployment.

Before running, copy the secrets example and fill in your values:

```bash
cp hosts/home-assistant/helm/values.secret.yml.example hosts/home-assistant/helm/values.secret.yml
# edit values.secret.yml
```

Then deploy:

```bash
hosts/home-assistant/scripts/install-ha.sh --config hosts/home-assistant/host.yml
```

## Updating config or upgrading the Helm chart

After the initial install, `run-helm-upgrade.sh` runs directly on the host. SSH in and run it from the repo:

```bash
ssh <user>@<host>
cd ~/stuff/homelab-provisioner
hosts/home-assistant/scripts/run-helm-upgrade.sh
```

This re-applies `hosts/home-assistant/helm/values.yml` and `hosts/home-assistant/helm/values.secret.yml` against the running release. Use it whenever you change Helm values or want to upgrade to a newer chart version.
