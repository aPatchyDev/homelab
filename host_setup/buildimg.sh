#!/bin/bash

cd $(dirname $(realpath "$0"))
source ./vars.sh

# Get flasher tool
FLASHER='bin/flasher-tool'
if [[ ! -d $CACHE_DIR || ! -x "${CACHE_DIR}/${FLASHER}" ]]; then
	require_cmd go
	export GOPATH="$(realpath ./$CACHE_DIR)"
	go install github.com/lxc/incus-os/incus-osd/cmd/flasher-tool@latest
fi

# Get certificate
if [ ! -f $CLIENT_CERT ]; then
	require_cmd incus
	mkdir -p $AUTH_DIR
	incus remote get-client-certificate > $CLIENT_CERT
fi

# Generate install seed tarball
TAR_FILE="seed.tar"
UNCHANGED='install.yaml'
CHANGED='incus.yaml'

yq ".preseed.certificates[].certificate = (load_str(\"${CLIENT_CERT}\") | trim)" ./incus.yaml > ${CACHE_DIR}/incus.yaml

tar -cf "${CACHE_DIR}/${TAR_FILE}" $UNCHANGED -C $CACHE_DIR $CHANGED

cd $CACHE_DIR
if [ -f *.img ]; then
	./$FLASHER -s ./$TAR_FILE -f img -i *.img
else
	./$FLASHER -s ./$TAR_FILE -f img
fi
