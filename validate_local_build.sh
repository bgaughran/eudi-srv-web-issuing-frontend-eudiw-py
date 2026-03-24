#!/bin/sh

set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$repo_dir"

venv_dir=${VENV_DIR:-$repo_dir/.venv-validate}
python_bin=${PYTHON_BIN:-python3}

"$python_bin" -m venv "$venv_dir"
. "$venv_dir/bin/activate"

python -m pip install --upgrade pip
python -m pip install -r app/requirements.txt

if [ -f package-lock.json ]; then
  npm ci
else
  npm install --no-fund --no-audit
fi

npm run build
python -m compileall app
bash -n configure_frontend_env.sh run_frontend.sh setup_backend_trust.sh

printf 'Validated issuer frontend dependencies in %s\n' "$venv_dir"