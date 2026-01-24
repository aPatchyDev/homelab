#!/bin/bash

# Adapted from https://github.com/community-scripts/ProxmoxVE/blob/c1fe8b91b4688493b76e2b1ace503ce4f0b5339a/tools/pve/post-pve-install.sh

echo 'Running post install script...'

# Remove legacy one-line style source list
rm -f /etc/apt/sources.list.d/*.list

# Remove PVE enterprise repository
# Enable PVE no subscription repository
FREE_REPO_FILE=''
FREE_REPO_ACTIVE=0
for file in /etc/apt/sources.list.d/*.sources; do
	if grep -q -e 'Components:.*pve-enterprise' -e 'enterprise.proxmox.com.*ceph' "$file"; then
		rm -f "$file"
	elif grep -q 'Components:.*pve-no-subscription' "$file"; then
		FREE_REPO_FILE="$file"
		if grep -E '^[^#]*Components:.*pve-no-subscription' "$file" >/dev/null; then
			REPO_ACTIVE=1
		fi
	fi
done

if [ -z "$FREE_REPO_FILE" ]; then
	cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
elif [ "$FREE_REPO_ACTIVE" -eq 0 ]; then
	sed -i '/^#\s*Types:/,/^$/s/^#\s*//' "$FREE_REPO_FILE"
fi

# Disable clustering services
if systemctl is-active --quiet pve-ha-lrm; then
	# High Availability
	systemctl disable -q --now pve-ha-lrm
	systemctl disable -q --now pve-ha-crm
	# Cluster communication
	systemctl disable -q --now corosync
fi

# Create ZFS dataset for Democratic CSI

ZPOOL=$(zpool list -H -o name | head -n 1)
zfs create "${ZPOOL}/k8s-storage"
apt update && apt install -y targetcli-fb

IQN='iqn.2025-01.local.zfs'
targetcli <<EOF
cd /iscsi
create $IQN
cd /iscsi/$IQN/tpg1
set attribute authentication=0
set attribute generate_node_acls=1
set attribute cache_dynamic_acls=1
set attribute demo_mode_write_protect=0
exit
EOF

# Done
echo 'Completed post install. Rebooting...'
reboot
