#!/bin/bash

set -eu

if [[ $# -lt 1 || $# -gt 2 || ! -f $1 ]]; then
	>&2 echo "Usage: $0 [img] <dev>"
	>&2 echo -e '\timg: Path to IncusOS USB image file'
	>&2 echo -e '\tdev: Device name as shown in `lsblk -d`'
	exit 1
elif [[ $# -eq 2 ]]; then
	ODEV=$2
else
	read -p 'Unplug target USB device and Press Enter ' TMP
	DEV_INIT="$(lsblk -dno name)"
	read -p 'Plug in target USB device and Press Enter ' tmp
	ODEV=$( { echo "$DEV_INIT"; lsblk -dno name; } | sort | uniq -u )
	echo
fi

IMG=$1

echo "Target image: $IMG"
echo "Target device: /dev/$ODEV"
if [[ -z $ODEV || ! -e /dev/$ODEV ]]; then
	>&2 echo "Device not found: /dev/$ODEV"
	exit 1
fi

read -p 'Proceed? (y/n) ' TMP
if [[ "$TMP" =~ ^[Yy] ]]; then
	SUDO=$( [ $(id -u) -eq 0 ] && echo || echo sudo )
	$SUDO umount -q /dev/$ODEV || true
	$SUDO dd bs=4M if=$IMG of=/dev/$ODEV status=progress
	$SUDO umount -q /dev/$ODEV || true
	exit 0
fi
exit 1
