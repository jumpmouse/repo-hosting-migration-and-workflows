#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd)"

source "$SCRIPT_DIR"/_env_vars.sh

echo "[clean_up] Stopping containers and cleaning up ports..."
"$SCRIPT_DIR"/stop.sh
echo "[clean_up] Removing existing containers..."
"$SCRIPT_DIR"/_clean.sh
