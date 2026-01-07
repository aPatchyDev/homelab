#!/bin/bash

cd $(dirname $(realpath "$0"))
source ./vars.sh

if [ ! -d $AUTH_DIR ]; then
	>&2 echo "Auth directory missing: $AUTH_DIR"
	exit 1
fi

require_cmd incus

# Add node to Incus CLI
incus remote add $NODE_NAME $NODE_IP
incus remote switch $NODE_NAME
incus admin os system security show > $RECOVERY_FILE
