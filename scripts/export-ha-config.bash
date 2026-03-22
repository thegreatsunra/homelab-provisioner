#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

NAMESPACE="home-assistant"
BACKUP_DIR="/tmp/ha-backup"

usage() {
	echo "Usage: $(basename "$0") [--namespace <namespace>] [--output <dir>]"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--namespace) NAMESPACE="$2"; shift 2 ;;
		--output)    BACKUP_DIR="$2"; shift 2 ;;
		*) usage ;;
	esac
done

BACKUP_FILE="$BACKUP_DIR/ha-config-$(date +%Y%m%d_%H%M%S).tar.gz"

mkdir -p "$BACKUP_DIR"

echo "Finding Home Assistant pod..."
POD=$(sudo k3s kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=home-assistant -o jsonpath='{.items[0].metadata.name}')

if [[ -z "$POD" ]]; then
	echo "Error: no Home Assistant pod found in namespace $NAMESPACE" >&2
	exit 1
fi

echo "Exporting config from pod $POD..."
# Pipe through cat so the redirect runs as the invoking user, not root
sudo k3s kubectl exec -n "$NAMESPACE" "$POD" -- tar czf - -C /config . | cat > "$BACKUP_FILE"

echo "Backup saved to $BACKUP_FILE"
