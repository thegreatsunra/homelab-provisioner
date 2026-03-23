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

**Why:** Validates the full pipeline is repeatable before relying on it for production use.
**How to apply:** When working on new features, consider whether they apply to both hosts. Keep the two host structures consistent.
