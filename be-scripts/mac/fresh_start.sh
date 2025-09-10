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


echo "[dev_fresh] Cleaning existing containers..."
"$SCRIPT_DIR"/stop.sh
"$SCRIPT_DIR"/_clean.sh

echo "[dev_fresh] Starting SQL Server and Azurite..."
echo "[dev_fresh] Creates database if missing..."
"$SCRIPT_DIR"/start_containers.sh

# echo "[dev_fresh] Running data migrations..."
# "$SCRIPT_DIR"/run_migrations.sh

# echo "[dev_fresh] Starting LoT.Api..."
# "$SCRIPT_DIR"/start_api.sh
