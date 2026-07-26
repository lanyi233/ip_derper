#!/bin/sh
set -eu

CERT_DIR="${DERP_CERTS:-/certs}"
HOST="${DERP_HOST:-127.0.0.1}"

mkdir -p "$CERT_DIR"

CERT_FILE="$CERT_DIR/$HOST.crt"
KEY_FILE="$CERT_DIR/$HOST.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    if echo "$HOST" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|:'; then
        SAN="IP:$HOST"
    else
        SAN="DNS:$HOST"
    fi
    openssl req \
        -x509 \
        -nodes \
        -days 730 \
        -newkey rsa:2048 \
        -keyout "$KEY_FILE" \
        -out "$CERT_FILE" \
        -subj "/CN=$HOST" \
        -addext "subjectAltName=$SAN"
fi

exec /app/derper \
    --hostname="$HOST" \
    --certmode=manual \
    --certdir="$CERT_DIR" \
    --stun="${DERP_STUN:-true}" \
    --a="${DERP_ADDR:-:443}" \
    --http-port="${DERP_HTTP_PORT:-80}" \
    --verify-clients="${DERP_VERIFY_CLIENTS:-false}" \
    "$@"
