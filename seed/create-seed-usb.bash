#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DISK=""
HOSTNAME="k3s-node"
SSH_KEY_PATH="$HOME/.ssh/id_ed25519.pub"
USERNAME="ubuntu"

while [[ $# -gt 0 ]]; do
	case "$1" in
		--disk)      DISK="$2";         shift 2 ;;
		--hostname)  HOSTNAME="$2";     shift 2 ;;
		--key)       SSH_KEY_PATH="$2"; shift 2 ;;
		--username)  USERNAME="$2";     shift 2 ;;
		*) echo "Unknown option: $1" >&2; exit 1 ;;
	esac
done

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TEMPLATE="$SCRIPT_DIR/user-data.yml"

if [[ -z "$DISK" ]]; then
	echo "Error: --disk is required." >&2
	echo "Usage: $0 --disk <disk> [--hostname <name>] [--key <path>] [--username <user>]" >&2
	echo "" >&2
	echo "Available disks:" >&2
	diskutil list >&2
	exit 1
fi

if [[ ! "$DISK" =~ ^/dev/disk[0-9]+$ ]]; then
	echo "Error: --disk must be a block device like /dev/disk4" >&2
	exit 1
fi

if [[ ! -f "$SSH_KEY_PATH" ]]; then
	echo "Error: SSH public key not found at $SSH_KEY_PATH" >&2
	exit 1
fi

if ! ssh-keygen -l -f "$SSH_KEY_PATH" >/dev/null 2>&1; then
	echo "Error: $SSH_KEY_PATH does not appear to be a valid SSH public key" >&2
	exit 1
fi

if [[ ! -f "$TEMPLATE" ]]; then
	echo "Error: user-data template not found at $TEMPLATE" >&2
	exit 1
fi

echo "Target disk info:"
diskutil info "$DISK" | grep -E 'Device|Media Name|Total Size|Protocol'
echo ""
echo "WARNING: This will ERASE $DISK and format it as FAT32 labeled CIDATA."
echo "Hostname: $HOSTNAME"
echo "Username: $USERNAME"
echo "SSH key:  $SSH_KEY_PATH"
echo ""
read -r -p "Continue? [y/N] " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
	echo "Aborted."
	exit 0
fi

WORK_DIR=$(mktemp -d)
trap 'rm -rf "$WORK_DIR"' EXIT

SSH_KEY_RAW=$(<"$SSH_KEY_PATH")
SSH_KEY_ESCAPED=$(printf '%s' "$SSH_KEY_RAW" | sed -e 's/[\/&]/\\&/g')

sed -e "s|@@HOSTNAME@@|$HOSTNAME|g" \
		-e "s|@@USERNAME@@|$USERNAME|g" \
		-e "s|@@SSH_KEY@@|$SSH_KEY_ESCAPED|g" \
		"$TEMPLATE" > "$WORK_DIR/user-data"

cat > "$WORK_DIR/meta-data" << EOF
instance-id: ubuntu-24-04-$HOSTNAME
local-hostname: $HOSTNAME
EOF

echo "Formatting $DISK as FAT32 (CIDATA)..."
diskutil eraseDisk FAT32 CIDATA MBRFormat "$DISK"

MOUNT_POINT="/Volumes/CIDATA"

echo "Waiting for volume to mount..."
for _ in {1..10}; do
	[[ -d "$MOUNT_POINT" ]] && break
	sleep 1
done
if [[ ! -d "$MOUNT_POINT" ]]; then
	echo "Error: volume did not mount at $MOUNT_POINT" >&2
	exit 1
fi

echo "Copying seed files..."
cp "$WORK_DIR/user-data" "$MOUNT_POINT/user-data"
cp "$WORK_DIR/meta-data" "$MOUNT_POINT/meta-data"

echo "Ejecting $DISK..."
mdutil -i off "$MOUNT_POINT" > /dev/null 2>&1 || true
diskutil eject "$DISK"

echo ""
echo "Done. Seed USB is ready for: $HOSTNAME"
