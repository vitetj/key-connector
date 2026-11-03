#!/bin/bash
set -eu

# Config éditable par l'admin : /app/data/env (Terminal Cloudron ou File manager)
if [[ ! -f /app/data/env ]]; then
    echo "==> Premier démarrage : création de /app/data/env"
    cp /app/pkg/env.template /app/data/env
fi

# Valeurs imposées par Cloudron (non surchargeables)
export DATA_FOLDER=/app/data
export ROCKET_ADDRESS=0.0.0.0
export ROCKET_PORT=8000
export WEB_VAULT_FOLDER=/web-vault
export DOMAIN="https://${CLOUDRON_APP_DOMAIN}"

# SMTP via l'addon sendmail de Cloudron
if [[ -n "${CLOUDRON_MAIL_SMTP_SERVER:-}" ]]; then
    export SMTP_HOST="${CLOUDRON_MAIL_SMTP_SERVER}"
    export SMTP_PORT="${CLOUDRON_MAIL_SMTP_PORT}"
    export SMTP_SECURITY=off
    export SMTP_USERNAME="${CLOUDRON_MAIL_SMTP_USERNAME}"
    export SMTP_PASSWORD="${CLOUDRON_MAIL_SMTP_PASSWORD}"
    export SMTP_FROM="${CLOUDRON_MAIL_FROM}"
    export SMTP_FROM_NAME="${CLOUDRON_MAIL_FROM_DISPLAY_NAME:-Vaultwarden TEST}"
fi

# Charge la config admin
set -a
# shellcheck disable=SC1091
source /app/data/env
set +a

# Garde-fou : refuse de démarrer tant que le SSO/Key Connector n'est pas renseigné
if [[ "${KEY_CONNECTOR_ENABLED:-false}" == "true" && "${KEY_CONNECTOR_URL:-}" == *"CHANGEME"* ]]; then
    echo "!! KEY_CONNECTOR_URL non renseigné dans /app/data/env, arrêt."
    sleep 3600
    exit 1
fi

echo "==> Démarrage Vaultwarden KC (TEST) sur ${DOMAIN}"
exec /vaultwarden
