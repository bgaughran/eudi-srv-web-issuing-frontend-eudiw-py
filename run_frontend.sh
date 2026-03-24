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

flask --app app run --debug --host=0.0.0.0 --port="${FRONTEND_PORT}" --cert="${FRONTEND_CERT_FILE}" --key="${FRONTEND_KEY_FILE}"
