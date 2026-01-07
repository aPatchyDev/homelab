# Assume pwd is this directory
set -eu

CACHE_DIR='./cache'
AUTH_DIR='./auth'

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		>&2 echo "$1" unavailable. Aborting...
		exit 1
	fi
}

require_cmd yq	# Require https://github.com/mikefarah/yq v4

# Incus credentials
CLIENT_CERT="${AUTH_DIR}/secret_client.crt"
RECOVERY_FILE="{AUTH_DIR}/secret_recovery.yaml"

# Incus variables
NODE_NAME='homelab'
NODE_IP=$(yq .minipc.nic[0].ip4 ../secret_device.json)
