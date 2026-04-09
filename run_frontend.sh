#!/bin/bash

set -euo pipefail

# Activate Python virtual environment
source .venv/bin/activate

# Configure local frontend environment
./configure_frontend_env.sh

# Run backend trust setup
./setup_backend_trust.sh

# Ensure REQUESTS_CA_BUNDLE is set for Flask process
export REQUESTS_CA_BUNDLE="$PWD/custom_ca_bundle.pem"

# Start Flask frontend with HTTPS, using custom CA bundle
FRONTEND_PORT="${FRONTEND_PORT:-5003}"
FRONTEND_CERT_FILE="${FRONTEND_CERT_FILE:-server.crt}"
FRONTEND_KEY_FILE="${FRONTEND_KEY_FILE:-server.key}"
FLASK_DEBUG_MODE="${FLASK_DEBUG_MODE:-0}"
ISSUER_URL="${ISSUER_URL:-https://127.0.0.1:5002}"
ISSUER_METADATA_URL="${ISSUER_URL%/}/.well-known/openid-credential-issuer"

echo "Waiting for issuer metadata at ${ISSUER_METADATA_URL}..."
for _ in $(seq 1 30); do
	if curl --silent --show-error --fail --cacert "$REQUESTS_CA_BUNDLE" "$ISSUER_METADATA_URL" >/dev/null; then
		break
	fi
	sleep 1
done

curl --silent --show-error --fail --cacert "$REQUESTS_CA_BUNDLE" "$ISSUER_METADATA_URL" >/dev/null

if [[ "$FLASK_DEBUG_MODE" == "1" ]]; then
	exec flask --app app run --debug --no-reload --host=0.0.0.0 --port="${FRONTEND_PORT}" --cert="${FRONTEND_CERT_FILE}" --key="${FRONTEND_KEY_FILE}"
fi

exec flask --app app run --host=0.0.0.0 --port="${FRONTEND_PORT}" --cert="${FRONTEND_CERT_FILE}" --key="${FRONTEND_KEY_FILE}"
