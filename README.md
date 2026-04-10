# homelab-provisioner

Automated provisioning for homelab Ubuntu hosts.

Includes tooling for deploying and updating Home Assistant via Helm on k3s.

## Quick Start

**Step 1 — Create the Ubuntu Server installer USB**

Download the [Ubuntu Server LTS ISO](https://ubuntu.com/download/server) and flash it to a USB drive with [balenaEtcher](https://etcher.balena.io).

**Step 2 — Create the seed USB (macOS):**

```bash
diskutil list
seed/create-seed-usb.sh --disk /dev/<disk> --hostname <hostname> --username <username>
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

Create a host config file (e.g. `hosts/<name>/host.yml`):

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
ansible/run-playbook.sh --config hosts/<name>/host.yml
```

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
