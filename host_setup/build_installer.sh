#!/bin/bash

CACHE_DIR='cache'
REPO_KEY='proxmox-trixie.gpg'
ISO_SRC_FILE='proxmox.iso'

if [ ! -d $CACHE_DIR ]; then
	mkdir -p $CACHE_DIR
fi
if [ ! -f "${CACHE_DIR}/${REPO_KEY}" ]; then
	wget -O "${CACHE_DIR}/${REPO_KEY}" https://enterprise.proxmox.com/debian/proxmox-archive-keyring-trixie.gpg
	chmod 644 "${CACHE_DIR}/${REPO_KEY}"
fi
if [ ! -f "${CACHE_DIR}/${ISO_SRC_FILE}" ]; then
	wget -O "${CACHE_DIR}/${ISO_SRC_FILE}" --show-progress -nv https://enterprise.proxmox.com/iso/proxmox-ve_9.1-1.iso
fi

#if command -v podman >/dev/null 2>&1; then
#	# Slower than docker
#	podman build -o $CACHE_DIR --build-context root=.. --layers=false --security-opt=label=disable .
if command -v docker >/dev/null 2>&1; then
	docker build -o $CACHE_DIR --build-context root=.. .
else
	>&2 echo 'Docker required for building auto installer'
	exit 1
fi
