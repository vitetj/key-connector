# Image de test du fork acul021 (Vaultwarden + PR #7419 Key Connector).
# Le tag "testing" bouge : épingle le digest une fois testé, ex.
#   FROM ghcr.io/acul021/vaultwarden@sha256:<digest>
FROM ghcr.io/acul021/vaultwarden:testing@sha256:36637fb509eaaaa0b23d654ea3b2d35197d62a5626a3dd8dc520a057b18f42ba

# Cloudron : système de fichiers en lecture seule sauf /app/data, /tmp, /run.
RUN mkdir -p /app/pkg /app/data
COPY start.sh env.template /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD ["/app/pkg/start.sh"]
