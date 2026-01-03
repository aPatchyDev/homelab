#!/bin/bash

set -eu

if ! command -v incus >/dev/null 2>&1; then
	>&2 echo 'Incus CLI unavailable. Aborting...'
	exit 1
fi
if ! command -v age >/dev/null 2>&1; then
	>&2 echo 'age unavailable. Aborting...'
	exit 1
fi

AUTH_DIR='./auth'
if [ ! -d $AUTH_DIR ]; then
	>&2 echo "Auth directory missing: $AUTH_DIR"
	exit 1
fi

# Add node to Incus CLI
NODE_NAME='homelab'
NODE_IP='192.168.123.111'
RECOVERY_FILE="${AUTH_DIR}/secret_recovery.yaml"

incus remote add $NODE_NAME $NODE_IP
incus remote switch $NODE_NAME
incus admin os system security show > $RECOVERY_FILE
