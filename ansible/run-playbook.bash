#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Run an Ansible playbook against a target host.
#
# Options:
#   --target    <ip-or-hostname>   Required. Target host.
#   --playbook  <file>             Required. Playbook filename (relative to playbooks/).
#   --user      <username>         SSH user. Default: ubuntu.
#   --k3s-args       <args>        Extra args passed to the K3s installer.
#                                  For Home Assistant (host networking):
#                                    --k3s-args "--disable=traefik --disable=servicelb"
#   --extra-ports    <ports>       Comma-separated list of UFW ports to allow.
#                                  For Home Assistant:
#                                    --extra-ports "8123/tcp"

ANSIBLE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

TARGET=""
ANSIBLE_USER="ubuntu"
PLAYBOOK=""
K3S_ARGS=""
EXTRA_PORTS=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--target)       TARGET="$2";       shift 2 ;;
		--user)         ANSIBLE_USER="$2"; shift 2 ;;
		--playbook)     PLAYBOOK="$2";     shift 2 ;;
		--k3s-args)     K3S_ARGS="$2";     shift 2 ;;
		--extra-ports)  EXTRA_PORTS="$2";  shift 2 ;;
		*) echo "Unknown option: $1" >&2; exit 1 ;;
	esac
done

if [[ -z "$TARGET" ]] || [[ -z "$PLAYBOOK" ]]; then
	echo "Usage: $0 --target <ip-or-hostname> --playbook <file> [--user <username>] [--k3s-args <args>] [--extra-ports <ports>]" >&2
	echo "  Example: $0 --target 192.168.1.100 --user gordo --playbook provision-host.yml --k3s-args \"--disable=traefik --disable=servicelb\" --extra-ports \"8123/tcp\"" >&2
	exit 1
fi

PLAYBOOK_PATH="$ANSIBLE_DIR/playbooks/$PLAYBOOK"

if [[ ! -f "$PLAYBOOK_PATH" ]]; then
	echo "Error: playbook not found at $PLAYBOOK_PATH" >&2
	exit 1
fi

echo "Running Ansible playbook: $PLAYBOOK"
echo "Target: $TARGET"
echo "User: $ANSIBLE_USER"
echo ""

cd "$ANSIBLE_DIR"

EXTRA_VARS=()
[[ -n "$K3S_ARGS" ]]    && EXTRA_VARS+=(-e "k3s_install_args=${K3S_ARGS}")
[[ -n "$EXTRA_PORTS" ]] && EXTRA_VARS+=(-e "firewall_extra_ports=[${EXTRA_PORTS}]")

ansible-playbook \
	-i "$TARGET," \
	-u "$ANSIBLE_USER" \
	"${EXTRA_VARS[@]}" \
	"playbooks/$PLAYBOOK"

echo ""
echo "Playbook complete"
