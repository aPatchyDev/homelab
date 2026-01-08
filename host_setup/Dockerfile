FROM debian:latest AS build

COPY cache/proxmox-trixie.gpg /usr/share/keyrings/proxmox-archive-keyring.gpg
COPY proxmox_apt.sources /etc/apt/sources.list.d/pve-install-repo.sources
RUN apt update && apt install -y proxmox-auto-install-assistant xorriso yq

# Use https://github.com/kislyuk/yq for YAML -> TOML

WORKDIR /workspace
COPY secret_autoinstall.yaml postinstall.sh .
COPY --from=root secret_device.json .
RUN --mount=source=cache/proxmox.iso,target=proxmox.iso \
	yq -t -s '.[0].network["interface-name-pinning"].mapping = ( \
		.[1].minipc.nic | to_entries | map( \
			{(.value.mac|ascii_downcase) : ("eth" + (.key|tostring))} \
		) | add \
	) | .[0]' secret_autoinstall.yaml secret_device.json > answer.toml \
	&& proxmox-auto-install-assistant prepare-iso \
		--output proxmox_autoinstaller.iso \
		--on-first-boot postinstall.sh \
		--fetch-from iso --answer-file answer.toml \
		proxmox.iso

FROM scratch
COPY --from=build /workspace/proxmox_autoinstaller.iso /workspace/answer.toml /
