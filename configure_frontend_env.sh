#!/bin/bash

set -euo pipefail

detect_lan_ip() {
    ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true
}

DETECTED_LAN_IP="$(detect_lan_ip)"

MYIP="${MYIP:-${DETECTED_LAN_IP:-localhost}}"
AUTH_PORT="${AUTH_PORT:-5001}"
ISSUER_PORT="${ISSUER_PORT:-5002}"
FRONTEND_PORT="${FRONTEND_PORT:-5003}"

FRONTEND_URL="https://${MYIP}:${FRONTEND_PORT}"
ISSUER_URL="https://${MYIP}:${ISSUER_PORT}"
OAUTH_URL="https://${MYIP}:${AUTH_PORT}"
FRONTEND_ID="${FRONTEND_ID:-5d725b3c-6d42-448e-8bfd-1eff1fcf152d}"
LOG_DIR="${LOG_DIR:-/tmp/issuer_frontend/log_dev}"
CREDENTIALS_SUPPORTED="${CREDENTIALS_SUPPORTED:-eu.europa.ec.eudi.pid_mdoc,eu.europa.ec.eudi.pid_vc_sd_jwt,eu.europa.ec.eudi.mdl_mdoc}"

mkdir -p "$LOG_DIR"

if [ ! -f .env ] && [ -f .env.example ]; then
  cp .env.example .env
fi

MYIP="$MYIP" \
AUTH_PORT="$AUTH_PORT" \
ISSUER_PORT="$ISSUER_PORT" \
FRONTEND_PORT="$FRONTEND_PORT" \
FRONTEND_ID="$FRONTEND_ID" \
LOG_DIR="$LOG_DIR" \
CREDENTIALS_SUPPORTED="$CREDENTIALS_SUPPORTED" \
python3 - <<'PY'
from pathlib import Path
import os

env_path = Path(".env")
if env_path.exists():
    lines = env_path.read_text().splitlines()
else:
    lines = []

myip = os.environ["MYIP"]
auth_port = os.environ["AUTH_PORT"]
issuer_port = os.environ["ISSUER_PORT"]
frontend_port = os.environ["FRONTEND_PORT"]
frontend_id = os.environ["FRONTEND_ID"]
log_dir = os.environ["LOG_DIR"]
credentials_supported = os.environ["CREDENTIALS_SUPPORTED"]

updates = {
    "MYIP": myip,
    "AUTH_PORT": auth_port,
    "ISSUER_PORT": issuer_port,
    "FRONTEND_PORT": frontend_port,
    "SERVICE_URL": f"https://{myip}:{frontend_port}",
    "FRONTEND_ID": frontend_id,
    "ISSUER_URL": f"https://{myip}:{issuer_port}",
    "OAUTH_URL": f"https://{myip}:{auth_port}",
    "LOG_DIR": log_dir,
    "CREDENTIALS_SUPPORTED": credentials_supported,
}

seen = set()
out = []

for line in lines:
    stripped = line.strip()
    if not stripped or stripped.startswith("#") or "=" not in line:
        out.append(line)
        continue

    key = line.split("=", 1)[0].strip()
    if key in updates:
        out.append(f"{key}={updates[key]}")
        seen.add(key)
    else:
        out.append(line)

for key, value in updates.items():
    if key not in seen:
        out.append(f"{key}={value}")

env_path.write_text("\n".join(out) + "\n")
print(f"Updated {env_path}")
PY

echo
echo "Frontend .env now set to:"
echo "  SERVICE_URL=${FRONTEND_URL}"
echo "  FRONTEND_ID=${FRONTEND_ID}"
echo "  ISSUER_URL=${ISSUER_URL}"
echo "  OAUTH_URL=${OAUTH_URL}"
echo "  LOG_DIR=${LOG_DIR}"
echo "  CREDENTIALS_SUPPORTED=${CREDENTIALS_SUPPORTED}"
