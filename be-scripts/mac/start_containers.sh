#!/bin/zsh
set -euo pipefail

# Fresh local setup for macOS
# - Removes old containers
# - Starts MSSQL, creates DB
# - Starts Azurite
# - Runs migrations
# - Starts API

SCRIPT_DIR="$(cd -- "$(dirname "$0")" >/dev/null 2>&1; pwd)"

source "$SCRIPT_DIR"/_env_vars.sh

echo "[dev_fresh] Starting SQL Server..."
"$SCRIPT_DIR"/_start_mssql.sh

echo "[dev_fresh] Creating database if missing..."
"$SCRIPT_DIR"/_create_db.sh

echo "[dev_fresh] Starting Azurite..."
"$SCRIPT_DIR"/_start_azurite.sh
