#!/bin/bash
set -eu

if [[ ! -f /app/data/env ]]; then
    echo "==> Premier démarrage : création de /app/data/env"
    cp /app/pkg/env.template /app/data/env
fi

export KC_BIND_ADDR=0.0.0.0:8081
export KC_DATABASE_URL="sqlite:///app/data/keyconnector.db?mode=rwc"

set -a
# shellcheck disable=SC1091
source /app/data/env
set +a

# --- Clé de chiffrement au repos ---
# TEST : générée dans /app/data si absente -> ELLE PART DANS LES SAUVEGARDES CLOUDRON
# avec la base. Inacceptable en prod (la clé doit venir d'un secret store séparé).
if [[ -z "${KC_ENCRYPTION_KEY:-}" && -z "${KC_ENCRYPTION_KEY_PATH:-}" ]]; then
    if [[ ! -f /app/data/kc_encryption_key ]]; then
        echo "==> Génération de /app/data/kc_encryption_key (TEST)"
        umask 077
        openssl rand -base64 32 > /app/data/kc_encryption_key
    fi
    export KC_ENCRYPTION_KEY_PATH=/app/data/kc_encryption_key
fi

# Un issuer non renseigné ne doit pas écraser celui découvert en option B
[[ "${KC_JWT_ISSUER:-}" == *"CHANGEME"* ]] && unset KC_JWT_ISSUER

# --- Vérification des tokens Vaultwarden ---
# Clé statique si /app/data/identity.pub.pem existe (recommandé : aucun flux KC -> Vaultwarden)
if [[ -f /app/data/identity.pub.pem ]]; then
    export KC_IDENTITY_PUBLIC_KEY_PATH=/app/data/identity.pub.pem
    unset KC_IDENTITY_AUTHORITY || true
    if [[ -z "${KC_JWT_ISSUER:-}" ]]; then
        echo "!! identity.pub.pem présent mais KC_JWT_ISSUER vide dans /app/data/env, arrêt."
        sleep 3600; exit 1
    fi
elif [[ -z "${KC_IDENTITY_AUTHORITY:-}" || "${KC_IDENTITY_AUTHORITY}" == *"CHANGEME"* ]]; then
    echo "!! Ni identity.pub.pem ni KC_IDENTITY_AUTHORITY valide, arrêt."
    sleep 3600; exit 1
fi

echo "==> Démarrage Key Connector (TEST)"
exec /app/pkg/key-connector
