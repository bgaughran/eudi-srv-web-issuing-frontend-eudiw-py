#!/bin/bash

set -euo pipefail

# Fetch the shared local HTTPS certificate used by the issuer/auth services.
BACKEND_HOST="${BACKEND_HOST:-192.168.0.110}"
BACKEND_PORT="${BACKEND_PORT:-5001}"
BACKEND_CERT="${BACKEND_CERT:-backend.crt}"
CUSTOM_CA_BUNDLE="${CUSTOM_CA_BUNDLE:-custom_ca_bundle.pem}"

echo "Fetching backend certificate from ${BACKEND_HOST}:${BACKEND_PORT}..."
echo | openssl s_client -connect ${BACKEND_HOST}:${BACKEND_PORT} -showcerts 2>/dev/null \
  | awk '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/{print $0}' > "$BACKEND_CERT"

echo "Locating Python certifi CA bundle..."
PYTHON_CA_BUNDLE=$(python -c "import certifi; print(certifi.where())")

echo "Creating custom CA bundle..."
cat "$PYTHON_CA_BUNDLE" "$BACKEND_CERT" > "$CUSTOM_CA_BUNDLE"

echo "Exporting REQUESTS_CA_BUNDLE environment variable..."
export REQUESTS_CA_BUNDLE="$PWD/$CUSTOM_CA_BUNDLE"
echo "Custom CA bundle created and REQUESTS_CA_BUNDLE set: $CUSTOM_CA_BUNDLE"
echo "Your Python requests will now trust the backend's self-signed certificate."
