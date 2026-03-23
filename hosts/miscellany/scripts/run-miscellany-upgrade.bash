#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MOSQUITTO_VALUES="$SCRIPT_DIR/../mosquitto/values.yml"
MOSQUITTO_SECRETS="$SCRIPT_DIR/../mosquitto/values.secret.yml"
XCEL_DIR="$SCRIPT_DIR/../xcel-itron2mqtt"
XCEL_SECRETS="$XCEL_DIR/config.secret.yml"
XCEL_CERTS="$XCEL_DIR/certs"

# Read a value from a simple flat YAML file (key: "value" format).
read_yaml() {
	grep "^${1}:" "$2" | sed 's/^[^:]*:[[:space:]]*//' | tr -d '"'"'"
}

if [[ ! -f "$MOSQUITTO_SECRETS" ]]; then
	echo "Error: Mosquitto secrets not found at $MOSQUITTO_SECRETS" >&2
	exit 1
fi

if [[ ! -f "$XCEL_SECRETS" ]]; then
	echo "Error: xcel-itron2mqtt secrets not found at $XCEL_SECRETS" >&2
	exit 1
fi

if [[ ! -f "$XCEL_CERTS/.cert.pem" ]] || [[ ! -f "$XCEL_CERTS/.key.pem" ]]; then
	echo "Error: certs not found at $XCEL_CERTS" >&2
	exit 1
fi

KUBECONFIG_TMP=$(mktemp)
trap 'rm -f "$KUBECONFIG_TMP"' EXIT
sudo k3s kubectl config view --raw | tee "$KUBECONFIG_TMP" > /dev/null
export KUBECONFIG="$KUBECONFIG_TMP"

# --- Mosquitto ---

helm repo add t3n https://storage.googleapis.com/t3n-helm-charts 2>/dev/null || true
helm repo update

sudo k3s kubectl create namespace mosquitto --dry-run=client -o yaml \
	| sudo k3s kubectl apply -f -

helm upgrade --install mosquitto t3n/mosquitto \
	--namespace mosquitto \
	-f "$MOSQUITTO_VALUES" \
	-f "$MOSQUITTO_SECRETS" \
	--wait --timeout 5m

echo "Mosquitto deployed."

# --- xcel-itron2mqtt ---

MQTT_SERVER=$(read_yaml mqtt_server "$XCEL_SECRETS")
MQTT_USER=$(read_yaml mqtt_user "$XCEL_SECRETS")
MQTT_PASSWORD=$(read_yaml mqtt_password "$XCEL_SECRETS")
METER_IP=$(read_yaml meter_ip "$XCEL_SECRETS")

sudo k3s kubectl create namespace xcel-itron2mqtt --dry-run=client -o yaml \
	| sudo k3s kubectl apply -f -

sudo k3s kubectl create secret generic xcel-itron2mqtt-certs \
	--namespace xcel-itron2mqtt \
	--from-file=".cert.pem=$XCEL_CERTS/.cert.pem" \
	--from-file=".key.pem=$XCEL_CERTS/.key.pem" \
	--dry-run=client -o yaml | sudo k3s kubectl apply -f -

sudo k3s kubectl create secret generic xcel-itron2mqtt-config \
	--namespace xcel-itron2mqtt \
	--from-literal="mqtt_server=$MQTT_SERVER" \
	--from-literal="mqtt_user=$MQTT_USER" \
	--from-literal="mqtt_password=$MQTT_PASSWORD" \
	--from-literal="meter_ip=$METER_IP" \
	--dry-run=client -o yaml | sudo k3s kubectl apply -f -

sudo k3s kubectl apply -f "$XCEL_DIR/deployment.yml"

echo "xcel-itron2mqtt deployed."
