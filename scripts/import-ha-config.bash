#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

NAMESPACE="home-assistant"
BACKUP_FILE="/tmp/ha-config.tar.gz"

usage() {
	echo "Usage: $(basename "$0") [--namespace <namespace>] [--file <backup.tar.gz>]"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--namespace) NAMESPACE="$2"; shift 2 ;;
		--file)      BACKUP_FILE="$2"; shift 2 ;;
		*) usage ;;
	esac
done

if [[ ! -f "$BACKUP_FILE" ]]; then
	echo "Error: backup file not found: $BACKUP_FILE" >&2
	exit 1
fi

echo "Finding Home Assistant pod..."
POD=$(sudo k3s kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/name=home-assistant -o jsonpath='{.items[0].metadata.name}')

if [[ -z "$POD" ]]; then
	echo "Error: no Home Assistant pod found in namespace $NAMESPACE" >&2
	exit 1
fi

echo "Copying backup to pod $POD..."
sudo k3s kubectl cp "$BACKUP_FILE" "$NAMESPACE/$POD:/tmp/ha-config.tar.gz"

echo "Extracting backup..."
sudo k3s kubectl exec -n "$NAMESPACE" "$POD" -- bash -lc "tar xzf /tmp/ha-config.tar.gz -C /config && chown -R 999:999 /config"

echo "Import complete"
