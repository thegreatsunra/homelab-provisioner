#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)

TARGET=""
SSH_USER="ubuntu"
SECRETS_FILE="$REPO_ROOT/home-assistant/helm/values.secret.yml"

usage() {
	echo "Usage: $(basename "$0") --target <ip-or-hostname> [--user <username>] [--secrets <file>]"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		--target)  TARGET="$2";       shift 2 ;;
		--user)    SSH_USER="$2";     shift 2 ;;
		--secrets) SECRETS_FILE="$2"; shift 2 ;;
		*) usage ;;
	esac
done

if [[ -z "$TARGET" ]]; then
	echo "Error: --target is required" >&2
	usage
fi

if [[ ! -f "$SECRETS_FILE" ]]; then
	echo "Error: secrets file not found: $SECRETS_FILE" >&2
	echo "Copy home-assistant/helm/values.secret.yml.example to values.secret.yml and fill in your values." >&2
	exit 1
fi

REPO_URL=$(git -C "$REPO_ROOT" remote get-url origin)

echo "Syncing repo on $TARGET..."
ssh "${SSH_USER}@${TARGET}" bash -s -- "$REPO_URL" << 'ENDSSH'
	set -euo pipefail
	REPO_URL="$1"
	if [[ -d ~/homelab-provisioner ]]; then
		git -C ~/homelab-provisioner pull
	else
		git clone "$REPO_URL" ~/homelab-provisioner
	fi
ENDSSH

echo "Copying secrets..."
scp "$SECRETS_FILE" "${SSH_USER}@${TARGET}:~/homelab-provisioner/home-assistant/helm/values.secret.yml"

echo "Deploying..."
ssh "${SSH_USER}@${TARGET}" '$HOME/homelab-provisioner/home-assistant/scripts/run-helm-upgrade.bash'
