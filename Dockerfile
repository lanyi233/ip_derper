# ----- [ Build] ----- #
FROM golang:1.25-alpine AS builder

WORKDIR /app/tailscale

COPY tailscale/go.mod tailscale/go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

COPY tailscale/ ./
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 go build -trimpath -buildvcs=false \
    -tags "netgo,osusergo" -ldflags "-s -w" -o /app/derper ./cmd/derper

# ----- [Run] ----- #
FROM alpine:3.22
WORKDIR /app

ENV DERP_ADDR=:443 \
    DERP_HTTP_PORT=80 \
    DERP_HOST=127.0.0.1 \
    DERP_CERTS=/certs/ \
    DERP_STUN=true \
    DERP_VERIFY_CLIENTS=false

RUN apk add --no-cache openssl

COPY --from=builder /app/derper /app/derper
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD []
