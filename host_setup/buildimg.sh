#!/bin/bash

set -eu

CACHE_DIR='./cache'
FLASHER="${CACHE_DIR}/bin/flasher-tool"
# Get flasher tool
if [[ ! -d $CACHE_DIR || ! -x $FLASHER ]]; then
	if ! command -v go >/dev/null 2>&1; then
		>&2 echo 'go unavailable. Aborting...'
		exit 1
	fi
	export GOPATH="$(realpath ./$CACHE_DIR)"
	go install github.com/lxc/incus-os/incus-osd/cmd/flasher-tool@latest
fi

# Require https://github.com/mikefarah/yq v4
if ! command -v yq >/dev/null 2>&1; then
	>&2 echo 'yq unavailable. Aborting...'
	exit 1
fi

# Get certificate
AUTH_DIR='./auth'
mkdir -p $AUTH_DIR
CLIENT_CERT="${AUTH_DIR}/client.crt"
if [ ! -f $CLIENT_CERT ]; then
	if ! command -v incus >/dev/null 2>&1; then
		>&2 echo 'Incus CLI unavailable. Aborting...'
		exit 1
	fi
	incus remote get-client-certificate > $CLIENT_CERT
fi

# Generate install seed tarball
TAR_FILE="${CACHE_DIR}/seed.tar"
yq ".preseed.certificates[].certificate = (load_str(\"${CLIENT_CERT}\") | trim)" ./incus.yaml > ${CACHE_DIR}/incus.yaml
tar -cf $TAR_FILE install.yaml -C $CACHE_DIR incus.yaml

cd $CACHE_DIR
if [ -f *.img ]; then
	${FLASHER/#$CACHE_DIR/.} -s ${TAR_FILE/#$CACHE_DIR/.} -f img -i *.img
else
	${FLASHER/#$CACHE_DIR/.} -s ${TAR_FILE/#$CACHE_DIR/.} -f img
fi
