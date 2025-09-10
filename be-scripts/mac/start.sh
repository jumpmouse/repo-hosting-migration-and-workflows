#!/bin/zsh
set -euo pipefail

# LoT local dev: one-command startup for macOS
# - Sets required env locally (no manual CLI exports needed)
# - Starts MSSQL and Azurite
# - Runs data migrations
# - Starts the main API

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd)"

source "$SCRIPT_DIR"/_env_vars.sh

echo "[dev_fresh] Starting SQL Server and Azurite..."
echo "[dev_fresh] Creates database if missing..."
"$SCRIPT_DIR"/_run_containers.sh

echo "[dev_up] Starting LoT.Api..."
"$SCRIPT_DIR"/start_api.sh
