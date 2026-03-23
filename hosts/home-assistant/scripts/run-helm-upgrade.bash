#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

NAMESPACE="home-assistant"
RELEASE="home-assistant"
VALUES_FILE="$SCRIPT_DIR/../helm/values.yml"
SECRETS_FILE="$SCRIPT_DIR/../helm/values.secret.yml"

usage() {
	echo "Usage: $(basename "$0") [--namespace <namespace>] [--release <release>] [--values <file>] [--secrets <file>]"
	exit 1
}

while [[ $# -gt 0 ]]; do
	case $1 in
		--namespace) NAMESPACE="$2"; shift 2 ;;
		--release)   RELEASE="$2";    shift 2 ;;
		--values)    VALUES_FILE="$2"; shift 2 ;;
		--secrets)   SECRETS_FILE="$2"; shift 2 ;;
		*) usage ;;
	esac
done

if [[ ! -f "$SECRETS_FILE" ]]; then
	echo "Error: secrets file not found: $SECRETS_FILE" >&2
	echo "Copy hosts/home-assistant/helm/values.secret.yml.example to hosts/home-assistant/helm/values.secret.yml and fill in your values." >&2
	exit 1
fi

KUBECONFIG_TMP=$(mktemp)
trap 'rm -f "$KUBECONFIG_TMP"' EXIT
sudo k3s kubectl config view --raw | tee "$KUBECONFIG_TMP" > /dev/null
export KUBECONFIG="$KUBECONFIG_TMP"

helm repo add pajikos https://pajikos.github.io/home-assistant-helm-chart/ 2>/dev/null || true
helm repo update

sudo k3s kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | sudo k3s kubectl apply -f -

helm upgrade --install "$RELEASE" pajikos/home-assistant \
	--namespace "$NAMESPACE" \
	-f "$VALUES_FILE" \
	-f "$SECRETS_FILE" \
	--wait --timeout 10m

echo "Home Assistant deployed to namespace: $NAMESPACE"
