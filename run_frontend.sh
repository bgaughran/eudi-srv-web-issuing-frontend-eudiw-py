#!/bin/bash

set -euo pipefail

ensure_frontend_assets() {
	local output_css="app/static/css/tailwind.css"
	local input_css="assets/input.css"
	local config_js="tailwind.config.js"
	local needs_build=0

	if [[ ! -f "$output_css" ]]; then
		needs_build=1
	elif [[ "$input_css" -nt "$output_css" ]] || [[ "$config_js" -nt "$output_css" ]] || [[ "package.json" -nt "$output_css" ]]; then
		needs_build=1
	fi

	if [[ "$needs_build" != "1" ]]; then
		return
	fi

	echo "Ensuring frontend Tailwind assets are built..."
	if [[ ! -x "node_modules/.bin/tailwindcss" ]]; then
		if [[ -f package-lock.json ]]; then
			npm ci
		else
			npm install --no-package-lock --no-fund --no-audit
		fi
	fi

	npm run build
}

# Activate Python virtual environment
source .venv/bin/activate

ensure_frontend_assets

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
