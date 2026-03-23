---
name: Project roadmap
description: Upcoming work planned for homelab-provisioner
type: project
---

Two major workstreams planned:

**Host 1 (tamematrix) — Home Assistant**
Full end-to-end dry run from scratch: burn seed USB → install Ubuntu → run Ansible playbooks → clone repo → install HA via install-ha.bash → export/import HA config/data. Goal is to validate the full provisioning pipeline before doing it for real.

**Host 2 — Mosquitto + xcel-itron2mqtt**
A second host running Mosquitto (MQTT broker) and xcel-itron2mqtt. Will need its own provisioning path under a new top-level folder (e.g. `mosquitto/` or similar), mirroring the `home-assistant/` structure. Secrets management and deployment patterns should be consistent with HA.

**Host config YAML**
Define a lightweight YAML file per host (e.g. `hosts/tamematrix.yml`) capturing hostname, SSH user, k3s args, extra ports, and any other flags currently passed ad-hoc via CLI. Scripts like `run-playbook.bash` and `create-seed-usb.bash` should accept `--host <name>` and read their values from the YAML instead of requiring all flags to be spelled out each time. Terminal history is not a config store.

**Pending Ansible/zsh tasks:**
- Add `updateallthethings` zsh alias that runs `apt update`, `apt upgrade`, `apt autoremove`
- Verify unattended-upgrades is configured for all updates, not just security
- Update zsh config so `updateallthethings` runs automatically on shell login, at most once per day

**Why:** Validates the full pipeline is repeatable before relying on it for production use.
**How to apply:** When working on new features, consider whether they apply to both hosts. Keep the two host structures consistent.
