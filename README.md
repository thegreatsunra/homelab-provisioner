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

## Upgrading

For a host that's already been through Quick Start. What to run depends on what changed.

**Host config changed** (packages, firewall rules, k3s install args, hardening) — re-run the same Ansible command from Quick Start Step 4:

```bash
ansible/run-playbook.sh --config hosts/<name>/host.yml
```

The playbook is idempotent, so this is safe to run any time — it only applies what's changed.

**App config changed** (Home Assistant, Mosquitto, or xcel-itron2mqtt — Helm values, image tags, deployment specs) — edit the relevant file (e.g. `hosts/home-assistant/helm/values.yml`), commit, and **push to `origin` first**. The deploy scripts have the host `git pull` from `origin`, not from your local checkout, so unpushed changes won't be picked up. Then, from your Mac:

```bash
hosts/home-assistant/scripts/install-ha.sh --config hosts/home-assistant/host.yml
hosts/miscellany/scripts/install-miscellany.sh --config hosts/miscellany/host.yml
```

These sync the repo on the host, copy over secrets/certs, and run the Helm upgrade. They require the following (gitignored, copy each from its adjacent `.example` file and fill in):

- `hosts/home-assistant/helm/values.secret.yml`
- `hosts/miscellany/mosquitto/values.secret.yml`
- `hosts/miscellany/xcel-itron2mqtt/config.secret.yml`
- `hosts/miscellany/xcel-itron2mqtt/certs/.cert.pem` and `.key.pem`

If those secrets/certs are missing locally but the host was already deployed once, they're most likely still sitting on the host — secrets are gitignored, so `git pull` never touches or removes them. Skip the copy step and upgrade directly on the host instead:

```bash
ssh <user>@<host>
cd ~/stuff/homelab-provisioner && git pull
hosts/home-assistant/scripts/run-helm-upgrade.sh        # Home Assistant host
hosts/miscellany/scripts/run-miscellany-upgrade.sh       # Miscellany host
```

**Dependency versions changed** (Dockerfile base image, `.pre-commit-config.yaml` hook revs, `ansible/requirements.txt` floors, Helm image tags in `values.yml` / `deployment.yml`) — these aren't automated; check each against upstream and bump by hand, then verify before pushing:

```bash
task ci
```

Then push and deploy as described above.

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
