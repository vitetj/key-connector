#!/bin/bash
# Épingle une nouvelle référence upstream dans le Dockerfile de l'app.
# Usage : scripts/pin-upstream.sh key-connector <commit-sha> | vaultwarden-kc <sha256:digest>
set -euo pipefail
app=$1; ref=$2
case "$app" in
  key-connector)
    sed -i "s/^ARG KC_COMMIT=.*/ARG KC_COMMIT=${ref}/" Dockerfile
    sed -i "s|^# Build depuis les sources, commit épinglé.*|# Build depuis les sources, commit épinglé ($(date -u +%Y-%m-%d))|" Dockerfile
    ;;
  vaultwarden-kc)
    sed -i "s|^FROM ghcr.io/acul021/vaultwarden.*|FROM ghcr.io/acul021/vaultwarden:testing@${ref}|" vaultwarden-kc/Dockerfile
    ;;
  *) echo "app inconnue: $app" >&2; exit 2 ;;
esac
