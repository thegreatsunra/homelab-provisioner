#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Run an Ansible playbook against a target host.
#
# Usage: run-playbook.bash --config <host-config.yml>
#
# Config file format (YAML):
#   host:     <ip-or-hostname>   Required.
#   user:     <username>         SSH user. Default: ubuntu.
#   playbook: <file>             Required. Playbook filename (relative to playbooks/).
#   vars:                        Optional. Ansible extra vars passed to the playbook.
#     k3s_install_args: "..."
#     firewall_extra_ports:
#       - 8123/tcp

ANSIBLE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--config) CONFIG="$2"; shift 2 ;;
		*) echo "Unknown option: $1" >&2; exit 1 ;;
	esac
done

if [[ -z "$CONFIG" ]]; then
	echo "Usage: $0 --config <host-config.yml>" >&2
	exit 1
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
ANSIBLE_USER=$(yq '.user // "ubuntu"' "$CONFIG")
PLAYBOOK=$(yq '.playbook' "$CONFIG")

PLAYBOOK_PATH="$ANSIBLE_DIR/playbooks/$PLAYBOOK"
if [[ ! -f "$PLAYBOOK_PATH" ]]; then
	echo "Error: playbook not found at $PLAYBOOK_PATH" >&2
	exit 1
fi

VARS_FILE=$(mktemp /tmp/ansible-vars-XXXXX.yml)
trap 'rm -f "$VARS_FILE"' EXIT
yq '.vars // {}' "$CONFIG" > "$VARS_FILE"

echo "Running Ansible playbook: $PLAYBOOK"
echo "Target: $TARGET"
echo "User: $ANSIBLE_USER"
echo ""

cd "$ANSIBLE_DIR"

ansible-playbook \
	-i "$TARGET," \
	-u "$ANSIBLE_USER" \
	-e "@$VARS_FILE" \
	"playbooks/$PLAYBOOK"

echo ""
echo "Playbook complete"
