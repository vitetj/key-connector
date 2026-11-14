# Build depuis les sources, commit épinglé (2026-11-14)
ARG KC_COMMIT=82887e2d1b309b079f0639a44465b76bbfecc524

FROM rust:1-slim AS build
ARG KC_COMMIT
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN git clone https://github.com/acul021/key-connector.git . \
    && git checkout "${KC_COMMIT}" \
    && cargo build --release --locked --bin key-connector

FROM debian:trixie-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /app/pkg /app/data
COPY --from=build /src/target/release/key-connector /app/pkg/key-connector
COPY start.sh env.template /app/pkg/
RUN chmod +x /app/pkg/start.sh

CMD ["/app/pkg/start.sh"]
