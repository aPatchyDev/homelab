#!/bin/bash

HOSTNAME=asdf yq eval '
	load("../secret_device.json") as $info |
	.config.dns.hostname = strenv(HOSTNAME) |
	.config.interfaces = ($info.minipc.nic | map({"name": .name, "addresses": [], "roles": []})) |
	.config.interfaces[0].addresses = ["dhcp4"] |
	.config.interfaces[0].roles = ["management", "cluster", "instances"] |
	.config.interfaces style = ""
' ./network.yaml

printf '\n\n\n'

CERT=./auth/secret_client.crt yq '
        load("../secret_device.json").minipc.nic as $nic |
        .preseed.certificates[0].certificate = (load_str(strenv(CERT)) | trim) |
        .preseed.networks[0].name = $nic[0].name |
        .preseed.networks[0].config."bridge.external_interfaces" = ($nic.[1:] | map(.name) | join(","))
' ./incus.yaml
