#!/bin/bash

if [ "$#" -ne 1 ]; then
	>&2 echo "Usage: $0 <access token>"
	exit 1
fi

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
---
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-auth-secret
  namespace: external-secrets
stringData:
  token: "$1"
EOF
