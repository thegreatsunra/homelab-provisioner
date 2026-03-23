#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Deploy Mosquitto and xcel-itron2mqtt to a remote host.
#
# Usage: install-miscellany.bash --config <host-config.yml> [--mosquitto-secrets <file>] [--xcel-secrets <file>] [--certs <dir>]
#
# Reads host and user from the config file. Clones/updates the repo on the
# remote host, copies secrets and certs, and runs the upgrade script.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../../.." && pwd)

CONFIG=""
MOSQUITTO_SECRETS="$REPO_ROOT/hosts/miscellany/mosquitto/values.secret.yml"
XCEL_SECRETS="$REPO_ROOT/hosts/miscellany/xcel-itron2mqtt/config.secret.yml"
CERTS_DIR="$REPO_ROOT/hosts/miscellany/xcel-itron2mqtt/certs"

usage() {
	echo "Usage: $(basename "$0") --config <host-config.yml> [--mosquitto-secrets <file>] [--xcel-secrets <file>] [--certs <dir>]"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config)             CONFIG="$2";           shift 2 ;;
		--mosquitto-secrets)  MOSQUITTO_SECRETS="$2"; shift 2 ;;
		--xcel-secrets)       XCEL_SECRETS="$2";     shift 2 ;;
		--certs)              CERTS_DIR="$2";         shift 2 ;;
		*) usage ;;
	esac
done

if [[ -z "$CONFIG" ]]; then
	echo "Error: --config is required" >&2
	usage
fi

if [[ ! -f "$CONFIG" ]]; then
	echo "Error: config file not found: $CONFIG" >&2
	exit 1
fi

if ! command -v yq &>/dev/null; then
	echo "Error: yq is required (brew install yq)" >&2
	exit 1
fi

TARGET=$(yq '.host' "$CONFIG")
SSH_USER=$(yq '.user // "ubuntu"' "$CONFIG")

for f in "$MOSQUITTO_SECRETS" "$XCEL_SECRETS"; do
	if [[ ! -f "$f" ]]; then
		echo "Error: secrets file not found: $f" >&2
		echo "Copy the corresponding .example file and fill in your values." >&2
		exit 1
	fi
done

if [[ ! -d "$CERTS_DIR" ]] || [[ ! -f "$CERTS_DIR/.cert.pem" ]] || [[ ! -f "$CERTS_DIR/.key.pem" ]]; then
	echo "Error: certs not found at $CERTS_DIR" >&2
	echo "Expected $CERTS_DIR/.cert.pem and $CERTS_DIR/.key.pem" >&2
	exit 1
fi

REPO_URL=$(git -C "$REPO_ROOT" remote get-url origin)

echo "Syncing repo on $TARGET..."
ssh "${SSH_USER}@${TARGET}" bash -s -- "$REPO_URL" << 'ENDSSH'
	set -euo pipefail
	REPO_URL="$1"
	if [[ -d ~/stuff/homelab-provisioner ]]; then
		git -C ~/stuff/homelab-provisioner pull
	else
		mkdir -p ~/stuff
		git clone "$REPO_URL" ~/stuff/homelab-provisioner
	fi
ENDSSH

echo "Copying Mosquitto secrets..."
scp "$MOSQUITTO_SECRETS" \
	"${SSH_USER}@${TARGET}:~/stuff/homelab-provisioner/hosts/miscellany/mosquitto/values.secret.yml"

echo "Copying xcel-itron2mqtt secrets..."
scp "$XCEL_SECRETS" \
	"${SSH_USER}@${TARGET}:~/stuff/homelab-provisioner/hosts/miscellany/xcel-itron2mqtt/config.secret.yml"

echo "Copying certs..."
ssh "${SSH_USER}@${TARGET}" \
	"mkdir -p ~/stuff/homelab-provisioner/hosts/miscellany/xcel-itron2mqtt/certs"
scp "$CERTS_DIR/.cert.pem" "$CERTS_DIR/.key.pem" \
	"${SSH_USER}@${TARGET}:~/stuff/homelab-provisioner/hosts/miscellany/xcel-itron2mqtt/certs/"

echo "Deploying..."
ssh "${SSH_USER}@${TARGET}" \
	'$HOME/stuff/homelab-provisioner/hosts/miscellany/scripts/run-miscellany-upgrade.bash'
