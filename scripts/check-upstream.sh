#!/bin/bash
# Compare la référence upstream épinglée dans le Dockerfile avec l'upstream réel.
# Usage : scripts/check-upstream.sh key-connector|vaultwarden-kc
# Sortie : "current=<ref> latest=<ref> changed=true|false" (format GITHUB_OUTPUT)
set -euo pipefail
app=$1
case "$app" in
  key-connector)
    current=$(sed -n 's/^ARG KC_COMMIT=\([0-9a-f]*\).*/\1/p' Dockerfile)
    latest=$(git ls-remote https://github.com/acul021/key-connector.git HEAD | cut -f1)
    ;;
  vaultwarden-kc)
    current=$(grep -o 'sha256:[0-9a-f]*' vaultwarden-kc/Dockerfile | head -1 || true)
    latest=$(docker buildx imagetools inspect ghcr.io/acul021/vaultwarden:testing --format '{{.Manifest.Digest}}')
    ;;
  *) echo "app inconnue: $app" >&2; exit 2 ;;
esac
changed=false; [[ "$current" != "$latest" ]] && changed=true
echo "current=$current"; echo "latest=$latest"; echo "changed=$changed"
