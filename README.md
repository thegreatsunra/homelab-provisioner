# homelab-provisioner

Automated provisioning for homelab Ubuntu hosts.

Includes tooling for deploying and updating Home Assistant via Helm on k3s.

## Quick Start

**Step 1 — Create the Ubuntu Server installer USB**

Download the [Ubuntu Server LTS ISO](https://ubuntu.com/download/server) and flash it to a USB drive with [balenaEtcher](https://etcher.balena.io).

**Step 2 — Create the seed USB (macOS):**

```bash
diskutil list
seed/create-seed-usb.bash --disk /dev/<disk> --hostname <hostname> --username <username>
```

**Step 3 — Boot the host:**

- Plug in both USB drives (seed USB + Ubuntu installer).
- Power on and press ESC (or BIOS equivalent) to select the Ubuntu installer USB as the boot device. The installer finds the seed USB automatically.
- Type `yes` and press Enter at the "Continue with autoinstall?" prompt — everything after that is unattended.
- Installs to the largest non-removable disk (the internal SSD) and reboots when done.
- cloud-init runs on first boot; when the final message appears, the machine is ready.

**Step 4 — Run Ansible (macOS):**

First-time setup:

```bash
brew install ansible yq
```

Create a host config file (e.g. `home-assistant/host.yml`):

```yaml
host: <ip-or-hostname>
user: <username>
playbook: provision-host.yml
vars:
  k3s_install_args: "--disable=traefik --disable=servicelb"
  firewall_extra_ports:
    - 8123/tcp
```

Then:

```bash
ansible/run-playbook.bash --config home-assistant/host.yml
```

## Home Assistant

### First-time install

`install-ha.bash` runs from macOS. It clones or updates the repo on the remote host, copies your secrets file, and runs the Helm deployment.

Before running, copy the secrets example and fill in your values:

```bash
cp home-assistant/helm/values.secret.yml.example home-assistant/helm/values.secret.yml
# edit values.secret.yml
```

Then deploy:

```bash
home-assistant/scripts/install-ha.bash --config home-assistant/host.yml
```

### Updating config or upgrading the Helm chart

After the initial install, `run-helm-upgrade.bash` runs directly on the host. SSH in and run it from the repo:

```bash
ssh <user>@<host>
cd ~/homelab-provisioner
home-assistant/scripts/run-helm-upgrade.bash
```

This re-applies `home-assistant/helm/values.yml` and `home-assistant/helm/values.secret.yml` against the running release. Use it whenever you change Helm values or want to upgrade to a newer chart version.

## Testing and Linting

```bash
task ci     # run everything in Docker (canonical)
task test   # run ansible-lint (locally)
task lint   # run shellcheck, yamllint, whitespace checks (locally)
```

Local dependencies if running outside Docker:

```bash
brew install ansible-lint pre-commit
```
