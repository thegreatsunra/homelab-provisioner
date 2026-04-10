# Miscellany

## First-time install

`install-miscellany.sh` runs from macOS. It clones or updates the repo on the remote host, copies your secrets and certs, and runs the Helm/kubectl deployment.

Before running, copy the secrets examples and fill in your values:

```bash
cp hosts/miscellany/mosquitto/values.secret.yml.example hosts/miscellany/mosquitto/values.secret.yml
# edit values.secret.yml — generate the password hash with mosquitto_passwd as noted in the example

cp hosts/miscellany/xcel-itron2mqtt/config.secret.yml.example hosts/miscellany/xcel-itron2mqtt/config.secret.yml
# edit config.secret.yml — set mqtt_server to the host IP or mosquitto.mosquitto.svc.cluster.local
```

Place the xcel-itron2mqtt TLS certs at:

```
hosts/miscellany/xcel-itron2mqtt/certs/.cert.pem
hosts/miscellany/xcel-itron2mqtt/certs/.key.pem
```

Run the Ansible playbook to provision the host (installs k3s, configures firewall for port 1883):

```bash
ansible/run-playbook.sh --config hosts/miscellany/host.yml
```

Then deploy:

```bash
hosts/miscellany/scripts/install-miscellany.sh --config hosts/miscellany/host.yml
```

## Updating config

After the initial install, `run-miscellany-upgrade.sh` runs directly on the host. SSH in and run it from the repo:

```bash
ssh <user>@<host>
cd ~/stuff/homelab-provisioner
hosts/miscellany/scripts/run-miscellany-upgrade.sh
```

This re-applies Mosquitto Helm values and recreates the xcel-itron2mqtt k8s Secrets and Deployment. Use it whenever you change config or want to redeploy.
