# homelab-provisioner

Automated provisioning for homelab Ubuntu hosts.

Includes additional tooling for migrating Home Assistant between hosts.

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
brew install ansible
```

Then:

```bash
ansible/run-playbook.bash --target <ip-or-hostname> --playbook provision-host.yml [--user <username>] [--k3s-args <args>]
```

This command connects to the host via SSH key.

Example for provisioning Home Assistant, which requires host networking:

```bash
ansible/run-playbook.bash --target <hostname>.local --user <username> --playbook provision-host.yml \
  --k3s-args "--disable=traefik --disable=servicelb" \
  --extra-ports "8123/tcp"
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
