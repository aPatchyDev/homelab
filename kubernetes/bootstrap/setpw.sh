#!/bin/bash

if [ "$#" -ne 2 ]; then
	>&2 echo "Usage: $0 <username> <bcrypt hash>"
	exit 1
fi

kubectl patch secret argocd-secret -n argocd --type merge -p "{\"stringData\": {\"accounts.$1.password\": \"$2\", \"accounts.$1.passwordMtime\": \"$(date -u +%FT%TZ)\"}}"
