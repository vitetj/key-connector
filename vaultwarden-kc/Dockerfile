# Image de test du fork acul021 (Vaultwarden + PR #7419 Key Connector).
# Le tag "testing" bouge : épingle le digest une fois testé, ex.
#   FROM ghcr.io/acul021/vaultwarden@sha256:<digest>
FROM ghcr.io/acul021/vaultwarden:testing

# Cloudron : système de fichiers en lecture seule sauf /app/data, /tmp, /run.
RUN mkdir -p /app/pkg /app/data
COPY start.sh env.template /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD ["/app/pkg/start.sh"]
