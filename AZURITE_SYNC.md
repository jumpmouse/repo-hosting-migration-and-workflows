# Azurite Blob Sync Guide (Local Emulator)

This guide shows how to seed Azurite (local Azure Storage emulator) with blobs from Azure, and how to avoid common pitfalls like nested prefixes (e.g., `content/content/*`).

- Emulator: Azurite in Docker
- Account (emulator): `devstoreaccount1`
- Blob endpoint: `http://127.0.0.1:10000/devstoreaccount1`
- Containers we seed: `content`, `video-private`, `video-public`

---

## Prerequisites
- Docker Desktop running (Azurite container up)
  - Recommended: start the local stack using `be-scripts/mac/start.sh` or `be-scripts/mac/fresh_start.sh` which starts Azurite automatically.
- AzCopy installed
  - macOS: `brew install --cask microsoft-azure-storage-explorer` (bundles AzCopy) or `brew install azcopy` (if available)
- Azure CLI installed (used to generate SAS tokens for Azurite): https://learn.microsoft.com/cli/azure/install-azure-cli
- No Azure secrets are stored in this repo. Use short-lived SAS tokens pasted in your shell when needed.

---

## Step 0: Create destination containers in Azurite (one-time)
Uploads require containers to exist. Create them once in the emulator.

```
# content (public read)
az storage container create --name content --public-access blob \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"

# video-public (public read)
az storage container create --name video-public --public-access blob \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"

# video-private (no public read)
az storage container create --name video-private \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1"
```

Verify containers exist:
```
az storage container list \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1" \
  --query "[].name" -o tsv
```

---

## Step 1: Ensure Azurite is running
- Start all local infra and API:
  - macOS: `be-scripts/mac/start.sh`
  - Windows: `be-scripts/windows/Start.ps1`
  - Linux: `be-scripts/linux/start.sh`
- Or just infra (internal):
  - macOS: `be-scripts/mac/_run_containers.sh`
  - Windows: `be-scripts/windows/_Run-Containers.ps1`
  - Linux: `be-scripts/linux/_run_containers.sh`

Azurite default emulator account/key:
- Account name: `devstoreaccount1`
- Account key: `Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==`

Connection string (copy/paste):
```
DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1
```

---

## Step 2: Download source blobs from Azure to a local temp folder
Use your Azure SAS tokens (Read + List) for each source container. Example:

- Content
```
mkdir -p /tmp/lot_content_sync
azcopy copy "https://lotstorageuat3.blob.core.windows.net/content?<AZURE_SAS>" \
  "/tmp/lot_content_sync" --recursive --log-level INFO
```

- Video (private)
```
mkdir -p /tmp/lot_video_private_sync
azcopy copy "https://lotstorageuat3.blob.core.windows.net/video-private?<AZURE_SAS>" \
  "/tmp/lot_video_private_sync" --recursive --log-level INFO
```

- Video (public)
```
mkdir -p /tmp/lot_video_public_sync
azcopy copy "https://lotstorageuat3.blob.core.windows.net/video-public?<AZURE_SAS>" \
  "/tmp/lot_video_public_sync" --recursive --log-level INFO
```

Notes:
- AzCopy will create subfolders named after the source container (e.g., `/tmp/lot_content_sync/content`). We'll use a wildcard on upload to avoid nesting in Azurite.

How to get SAS for Azure source containers:
- Portal: Storage account → Containers → <container> → top menu "Generate SAS" → select permissions (at least rl for download; add c, a, w for uploads if needed) → set expiry → Generate.
- CLI example (Read + List, valid for 24h):
```
az storage container generate-sas \
  --account-name <AZURE_ACCOUNT> \
  --name <container> \
  --permissions rl \
  --expiry $(date -u -v+24H '+%Y-%m-%dT%H:%M:%SZ') \
  --auth-mode login -o tsv
```

---

## Step 3: Generate SAS tokens for Azurite destination containers
Use Azure CLI to generate SAS for the emulator containers. Example (valid for 7 days):
```
# content
az storage container generate-sas \
  --name content \
  --permissions racwdl \
  --expiry 2025-12-31T23:59:59Z \
  --account-name devstoreaccount1 \
  --account-key "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==" \
  --auth-mode key -o tsv

# Repeat for video-private and video-public
```
Keep the output token and build the destination URL:
```
http://127.0.0.1:10000/devstoreaccount1/<container>?<EMULATOR_SAS>
```

---

## Step 4: Upload only the folder contents (avoid nesting)
Set lower concurrency if Azurite throttles (`AZCOPY_CONCURRENCY_VALUE=8`). Use wildcards so the contents land at the container root.

- Content
```
AZCOPY_CONCURRENCY_VALUE=8 azcopy copy \
  "/tmp/lot_content_sync/content/*" \
  "http://127.0.0.1:10000/devstoreaccount1/content?<EMULATOR_SAS>" \
  --recursive --from-to LocalBlob --overwrite true --log-level INFO
```

- Video (private)
```
AZCOPY_CONCURRENCY_VALUE=8 azcopy copy \
  "/tmp/lot_video_private_sync/video-private/*" \
  "http://127.0.0.1:10000/devstoreaccount1/video-private?<EMULATOR_SAS>" \
  --recursive --from-to LocalBlob --overwrite true --log-level INFO
```

- Video (public)
```
AZCOPY_CONCURRENCY_VALUE=8 azcopy copy \
  "/tmp/lot_video_public_sync/video-public/*" \
  "http://127.0.0.1:10000/devstoreaccount1/video-public?<EMULATOR_SAS>" \
  --recursive --from-to LocalBlob --overwrite true --log-level INFO
```

---

## Step 5: Verify and fix nesting if needed
Ensure there are no nested prefixes in Azurite, e.g., `content/content/*` should be empty.
```
az storage blob list --container-name content \
  --prefix "content/" \
  --connection-string "DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1" \
  --query "length(@)" -o tsv
```
If non-zero, delete the nested prefix and re-upload only the contents:
```
az storage blob delete-batch \
  --connection-string "<EMULATOR_CONNECTION_STRING>" \
  --source content \
  --pattern "content/*"
```

Spot-check container roots:
```
az storage blob list --container-name content \
  --num-results 20 \
  --connection-string "<EMULATOR_CONNECTION_STRING>" \
  --query "[].name" -o tsv
```

---

## Troubleshooting
- CompletedWithErrors / throttling: reduce concurrency
  - `AZCOPY_CONCURRENCY_VALUE=8` (or lower)
- HTTP warning: Azurite uses HTTP; this is expected locally.
- Network rule errors on delete-batch: Azurite typically allows all local traffic. If using real Azure by accident, check `az storage account show -n <name> --query networkRuleSet`.
- Migrations/API errors: make sure MSSQL and Azurite are running (`be-scripts/mac/start.sh`).

---

## Cleanup (optional)
```
rm -rf /tmp/lot_content_sync /tmp/lot_video_private_sync /tmp/lot_video_public_sync
```
