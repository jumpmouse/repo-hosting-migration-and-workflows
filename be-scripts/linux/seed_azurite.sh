#!/usr/bin/env bash
set -euo pipefail

# Seed Azurite with blobs from Azure Storage via local temp folders.
# - Downloads from Azure: content, video-private, video-public (if SAS provided)
# - Uploads only the folder contents to Azurite to avoid nested prefixes
# - Optionally verifies and cleans nested prefixes
#
# Requirements:
# - Docker (Azurite container running)
# - azcopy in PATH
# - Optional: Azure CLI `az` to auto-generate Azurite SAS tokens
#
# Inputs (env vars):
# - AZURE_ACCOUNT                  : Azure storage account name (source)
# - AZURE_CONTENT_SAS              : SAS for source 'content' container (no leading '?')
# - AZURE_VIDEO_PRIVATE_SAS        : SAS for source 'video-private' (no leading '?')
# - AZURE_VIDEO_PUBLIC_SAS         : SAS for source 'video-public' (no leading '?')
# - EMULATOR_SAS_CONTENT           : SAS for Azurite 'content' (no leading '?') [optional]
# - EMULATOR_SAS_VIDEO_PRIVATE     : SAS for Azurite 'video-private' (no leading '?') [optional]
# - EMULATOR_SAS_VIDEO_PUBLIC      : SAS for Azurite 'video-public' (no leading '?') [optional]
# - AZCOPY_CONCURRENCY_VALUE       : Concurrency (default 1)
# - CLEAN_TMP=1                    : If set, remove /tmp sync folders when done

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
AZCOPY_CONCURRENCY_VALUE="${AZCOPY_CONCURRENCY_VALUE:-1}"

# Azurite emulator constants
EMULATOR_ACCOUNT="devstoreaccount1"
EMULATOR_KEY="Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=="
EMULATOR_BASE="http://127.0.0.1:10000/${EMULATOR_ACCOUNT}"

TMP_CONTENT="/tmp/lot_content_sync"
TMP_VIDEO_PRIV="/tmp/lot_video_private_sync"
TMP_VIDEO_PUB="/tmp/lot_video_public_sync"

need_bin() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "ERROR: '$1' is required in PATH" >&2
    exit 1
  fi
}

maybe_warn_container() {
  if command -v docker >/dev/null 2>&1; then
    if ! docker ps --format '{{.Names}}' | grep -q '^azurite$'; then
      echo "WARN: Azurite container 'azurite' not detected. Ensure it's running (be-scripts/linux/start.sh or be-scripts/mac/start.sh)." >&2
    fi
  fi
}

ensure_emulator_sas() {
  if command -v az >/dev/null 2>&1; then
    # Only generate if missing
    local expiry
    expiry=$(date -u -d "+7 days" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -v+7d '+%Y-%m-%dT%H:%M:%SZ')
    if [ -z "${EMULATOR_SAS_CONTENT:-}" ]; then
      EMULATOR_SAS_CONTENT=$(az storage container generate-sas \
        --name content --permissions racwdl --expiry "$expiry" \
        --account-name "$EMULATOR_ACCOUNT" --account-key "$EMULATOR_KEY" \
        --auth-mode key -o tsv)
    fi
    if [ -z "${EMULATOR_SAS_VIDEO_PRIVATE:-}" ]; then
      EMULATOR_SAS_VIDEO_PRIVATE=$(az storage container generate-sas \
        --name video-private --permissions racwdl --expiry "$expiry" \
        --account-name "$EMULATOR_ACCOUNT" --account-key "$EMULATOR_KEY" \
        --auth-mode key -o tsv)
    fi
    if [ -z "${EMULATOR_SAS_VIDEO_PUBLIC:-}" ]; then
      EMULATOR_SAS_VIDEO_PUBLIC=$(az storage container generate-sas \
        --name video-public --permissions racwdl --expiry "$expiry" \
        --account-name "$EMULATOR_ACCOUNT" --account-key "$EMULATOR_KEY" \
        --auth-mode key -o tsv)
    fi
  else
    # Azure CLI missing; require SAS be provided
    if [ -z "${EMULATOR_SAS_CONTENT:-}" ] || [ -z "${EMULATOR_SAS_VIDEO_PRIVATE:-}" ] || [ -z "${EMULATOR_SAS_VIDEO_PUBLIC:-}" ]; then
      echo "ERROR: EMULATOR_SAS_* not set and Azure CLI 'az' not available to auto-generate. Export these SAS tokens (no leading '?')." >&2
      exit 1
    fi
  fi
}

# Check required tools
need_bin azcopy
maybe_warn_container

# Enforce single-threaded azcopy for reliability
export AZCOPY_CONCURRENCY_VALUE

# Prepare tmp folders
mkdir -p "$TMP_CONTENT" "$TMP_VIDEO_PRIV" "$TMP_VIDEO_PUB"

# Optional downloads from Azure if SAS present
if [ -n "${AZURE_ACCOUNT:-}" ] && [ -n "${AZURE_CONTENT_SAS:-}" ]; then
  echo "[seed] Downloading 'content' from Azure → $TMP_CONTENT ..."
  azcopy copy "https://${AZURE_ACCOUNT}.blob.core.windows.net/content?${AZURE_CONTENT_SAS}" \
    "$TMP_CONTENT" --recursive --log-level INFO
else
  echo "[seed] Skipping Azure download for 'content' (AZURE_ACCOUNT/AZURE_CONTENT_SAS not set)"
fi

if [ -n "${AZURE_ACCOUNT:-}" ] && [ -n "${AZURE_VIDEO_PRIVATE_SAS:-}" ]; then
  echo "[seed] Downloading 'video-private' from Azure → $TMP_VIDEO_PRIV ..."
  azcopy copy "https://${AZURE_ACCOUNT}.blob.core.windows.net/video-private?${AZURE_VIDEO_PRIVATE_SAS}" \
    "$TMP_VIDEO_PRIV" --recursive --log-level INFO
else
  echo "[seed] Skipping Azure download for 'video-private' (AZURE_ACCOUNT/AZURE_VIDEO_PRIVATE_SAS not set)"
fi

if [ -n "${AZURE_ACCOUNT:-}" ] && [ -n "${AZURE_VIDEO_PUBLIC_SAS:-}" ]; then
  echo "[seed] Downloading 'video-public' from Azure → $TMP_VIDEO_PUB ..."
  azcopy copy "https://${AZURE_ACCOUNT}.blob.core.windows.net/video-public?${AZURE_VIDEO_PUBLIC_SAS}" \
    "$TMP_VIDEO_PUB" --recursive --log-level INFO
else
  echo "[seed] Skipping Azure download for 'video-public' (AZURE_ACCOUNT/AZURE_VIDEO_PUBLIC_SAS not set)"
fi

# Ensure Azurite SAS tokens
ensure_emulator_sas

# Upload only contents (avoid nested prefixes)

echo "[seed] Uploading 'content' into Azurite (contents only)..."
azcopy copy "$TMP_CONTENT/content/*" \
  "${EMULATOR_BASE}/content?${EMULATOR_SAS_CONTENT}" \
  --recursive --from-to LocalBlob --overwrite true --log-level INFO

# video-private
if [ -d "$TMP_VIDEO_PRIV/video-private" ]; then
  echo "[seed] Uploading 'video-private' into Azurite (contents only)..."
  azcopy copy "$TMP_VIDEO_PRIV/video-private/*" \
    "${EMULATOR_BASE}/video-private?${EMULATOR_SAS_VIDEO_PRIVATE}" \
    --recursive --from-to LocalBlob --overwrite true --log-level INFO
fi

# video-public
if [ -d "$TMP_VIDEO_PUB/video-public" ]; then
  echo "[seed] Uploading 'video-public' into Azurite (contents only)..."
  azcopy copy "$TMP_VIDEO_PUB/video-public/*" \
    "${EMULATOR_BASE}/video-public?${EMULATOR_SAS_VIDEO_PUBLIC}" \
    --recursive --from-to LocalBlob --overwrite true --log-level INFO
fi

# Optional verify (if Azure CLI present)
if command -v az >/dev/null 2>&1; then
  CONN_STR="DefaultEndpointsProtocol=http;AccountName=${EMULATOR_ACCOUNT};AccountKey=${EMULATOR_KEY};BlobEndpoint=${EMULATOR_BASE}"
  for c in content video-private video-public; do
    count=$(az storage blob list --container-name "$c" --prefix "$c/" \
      --connection-string "$CONN_STR" --query 'length(@)' -o tsv)
    if [ "$count" != "0" ]; then
      echo "[verify] WARN: Found $count nested blobs under '$c/$c/'. Consider cleaning them:" >&2
      echo "az storage blob delete-batch --connection-string \"$CONN_STR\" --source $c --pattern '$c/*'" >&2
    else
      echo "[verify] OK: No nested prefix under '$c/$c/'"
    fi
  done
fi

# Cleanup temp
if [ "${CLEAN_TMP:-0}" = "1" ]; then
  echo "[seed] Cleaning up temp folders..."
  rm -rf "$TMP_CONTENT" "$TMP_VIDEO_PRIV" "$TMP_VIDEO_PUB"
fi

echo "[seed] Done."
