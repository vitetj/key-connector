# Build depuis les sources, commit épinglé (03/11/2026)
ARG KC_COMMIT=c52b886f6f3bf9a975b0b99a5896a163ede13b8a

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
