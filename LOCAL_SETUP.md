# Local Setup and Run Guide

This document explains how to install prerequisites and run the LoT backend locally on macOS, Windows, and Linux. It also shows how to use the helper scripts in the `be-scripts/` folder.

## Table of Contents
- [Project setup (one-time)](#project-setup-one-time)
- [Day-to-day work](#day-to-day-work)
- [macOS](#macos)
- [Local database options: migrations vs. Azure backup (recommended paths)](#local-database-options-migrations-vs-azure-backup-recommended-paths)
- [Windows](#windows)
- [Linux](#linux)
- [Notes and Troubleshooting](#notes-and-troubleshooting)
- [Quick start (macOS example)](#quick-start-macos-example)

- ## Project setup (one-time)

Use this once to prepare your machine. Then see “Day-to-day work”.

- Install prerequisites for your OS:
  - macOS: see [macOS > Prerequisites](#macos)
  - Windows: see [Windows > Prerequisites](#windows)
  - Linux: see [Linux > Prerequisites](#linux)
- Trust HTTPS developer certs: `dotnet dev-certs https --trust` (macOS/Windows; Linux varies)
- Ensure Docker is running.
- Optional: make shell scripts executable (macOS/Linux): `chmod +x be-scripts/{mac,linux}/*.sh`
- Optional: seed Azurite blobs later if you need real files (see [AZURITE_SYNC.md](./AZURITE_SYNC.md)).

## Day-to-day work

Pick one of the following flows:

- Makefile (OS-aware, simplest):
  ```bash
  make start      # start containers and API (no migrations)
  make fresh      # stop/clean, then full start
  make stop       # stop containers
  make migrate    # apply DB migrations only
  make clean      # remove containers
  make seed-azurite  # optional: sync blobs
  ```
  These targets delegate to scripts under `be-scripts/` based on your OS.

- OS-specific scripts:
  - macOS: `be-scripts/mac/start.sh`, `fresh_start.sh`, `stop.sh`, `run_migrations.sh`, `start_api.sh`
  - Windows: `be-scripts/windows/Start.ps1`, `Fresh-Start.ps1`, `Stop.ps1`, `Run-Migrations.ps1`, `Start-Api.ps1`
  - Linux: `be-scripts/linux/start.sh`, `fresh_start.sh`, `stop.sh`, `run_migrations.sh`, `start_api.sh`

Database data choices for local dev: see [Local database options: migrations vs. Azure backup](#local-database-options-migrations-vs-azure-backup-recommended-paths).

---

- API project: `LoT.Api/` (ASP.NET Core, Swagger enabled)
- Migrations API: `LoT.DataMigrations.Api/` (applies DB migrations via HTTP)
- Database: SQL Server (runs in Docker)
- Blob storage: Azurite (Azure Storage emulator in Docker)

Default ports
- API: https://localhost:7057 (HTTP: 5057) from `LoT.Api/Properties/launchSettings.json`
- Migrations API: https://localhost:7200 (HTTP: 5230)
- MSSQL: localhost:1433
- Azurite: blob endpoints on 10000/10001/10002

Configuration files
- API: `LoT.Api/appsettings.Development.json` (connection strings, blob config)
- Migrations API: `LoT.DataMigrations.Api/appsettings.Development.json` (DB and Basic auth)

The repo is preconfigured for:
- MSSQL in Docker with SA password `LoT_StrongP@ssw0rd1`
- Azurite for blobs: `BlobBaseUrl: http://127.0.0.1:10000/devstoreaccount1` and `BlobConnectionString: UseDevelopmentStorage=true`


## macOS

### Prerequisites
- Homebrew: https://brew.sh/
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- .NET 8 SDK (repo pins .NET 8 via `global.json`):
  - `brew install --cask dotnet-sdk@8`
- Trust HTTPS developer certs (one-time):
  - `dotnet dev-certs https --trust`

- AzCopy (required for blob sync):
  - `brew install --cask microsoft-azure-storage-explorer` (bundles AzCopy)
  - or `brew install azcopy` (if available)
- Azure CLI (required for SAS generation and verification):
  - Install: https://learn.microsoft.com/cli/azure/install-azure-cli

Blob sync (optional, for local blob content): see [AZURITE_SYNC.md](./AZURITE_SYNC.md).

### One-time database creation (rarely needed)
Migrations normally create the DB. If needed:
```zsh
docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'LoT_StrongP@ssw0rd1' -C -Q "IF DB_ID('LoT') IS NULL CREATE DATABASE [LoT];"
```

### Using helper scripts (recommended)
Note: For database setup choices (migrations vs. Azure backup import), see: [Local database options: migrations vs. Azure backup](#local-database-options-migrations-vs-azure-backup-recommended-paths).
Scripts live in `be-scripts/mac/`. Make them executable once:
```zsh
chmod +x be-scripts/mac/*.sh
```

- Start everything (infra → API):
```zsh
be-scripts/mac/start.sh
```
- Fresh start (stop/clean → infra → migrations → API):
```zsh
be-scripts/mac/fresh_start.sh
```
- Stop only (stop containers, free ports):
```zsh
be-scripts/mac/stop.sh
```
- Clean up (stop + remove containers):
```zsh
be-scripts/mac/clean_up.sh
```

Open Swagger when API is up:
```zsh
open https://localhost:7057/swagger
```

### Script catalog (macOS)
- `start.sh`: One-command local startup.
  - Loads env from `_env_vars.sh`.
  - Starts Azurite + MSSQL via `_run_containers.sh`.
  - Starts the API via `start_api.sh`.
- `fresh_start.sh`: Clean stop + container removal, then full start.
  - Calls `stop.sh` and `_clean.sh`, then `start_containers.sh`, `run_migrations.sh`, `start_api.sh`.
- `stop.sh`: Stops `mssql` and `azurite` containers and frees common dev ports.
- `clean_up.sh`: Stops containers and removes them (calls `_clean.sh`).
- `start_containers.sh`: Internal orchestration to start MSSQL and Azurite and ensure DB exists (calls `_start_mssql.sh`, `_create_db.sh`, `_start_azurite.sh`).
- `run_migrations.sh`: Boots `LoT.DataMigrations.Api` (HTTP profile) in background, calls `/api/DataMigration/migrate`, then stops it.
- `start_api.sh`: Runs `LoT.Api`.
- `_env_vars.sh`: Exports local env (Development, SQL, migrations credentials).
- `_run_containers.sh`: Starts Azurite and MSSQL containers directly.
- `_start_mssql.sh`, `_start_azurite.sh`: Start-or-run helper scripts.
- `_create_db.sh`: Ensures `LoT` DB exists in MSSQL.
- `_clean.sh`: Removes `mssql` and `azurite` containers if they exist.

Note: scripts prefixed with `_` are internal helpers and are not intended to be called directly in day-to-day usage.

Verify:
```zsh
open https://localhost:7057/swagger
curl -k https://localhost:7057/api/test
```

---

## Local database options: migrations vs. Azure backup (recommended paths)

You have two ways to populate your local SQL Server. Choose one based on your needs.

- **Simple dev (default, fast)**
  - Use `run_migrations.sh` (already part of `start.sh`) to create the schema and insert minimal/reference seed data.
  - Pros: no Azure secrets or large downloads. Good for general development.
  - Cons: data won’t match Azure.

- **Mirror Azure (exact data snapshot)**
  - Export a BACPAC from Azure SQL (Portal or `az sql db export`), download it locally, and import into the local SQL container.
  - Pros: schema+data exactly match Azure at the time of export.
  - Cons: requires Azure access and time to download/import; snapshot may lag code schema.

### Commands used in this repo

- **Drop local `LoT` database (safe if it exists; no-op if it doesn't):**

  1) Ensure the SQL container is running. Use either:
     - `be-scripts/mac/start_containers.sh` (macOS) or
     - `make start` (starts full stack) / `make migrate` (migrations only)

  2) Drop the database (idempotent — the script checks existence first):

  ```zsh
  docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'LoT_StrongP@ssw0rd1' -C -Q "
  IF DB_ID('LoT') IS NOT NULL
    BEGIN
      ALTER DATABASE [LoT] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
      DROP DATABASE [LoT];
    END"
  ```

  Notes:
  - If the container isn’t running, `docker exec mssql ...` will fail. Start containers first.
  - If the DB doesn’t exist, nothing is dropped (the `IF DB_ID` guard prevents errors).

- **Import Azure backup (BACPAC) into local SQL:**

  ```zsh
  sqlpackage \
    /Action:Import \
    /SourceFile:"backup/lot-uat3-database-2025-8-24-3-11.bacpac" \
    /TargetConnectionString:"Server=localhost,1433;Database=LoT;User ID=sa;Password=LoT_StrongP@ssw0rd1;Encrypt=False;TrustServerCertificate=True" \
    /p:CommandTimeout=0
  ```

  Tips:
  - Use an absolute path for `/SourceFile` if `sqlpackage` can’t find it.
  - `Encrypt=False;TrustServerCertificate=True` avoids TLS handshake issues with the local Docker SQL.
  - Do not run migrations after importing a backup unless you intentionally want to upgrade the snapshot’s schema to match newer code.

#### Windows/Linux equivalents and extra notes

- **Windows PowerShell (same container path, PowerShell-friendly quoting):**

  ```powershell
  docker exec mssql /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P 'LoT_StrongP@ssw0rd1' -C -Q "IF DB_ID('LoT') IS NOT NULL BEGIN ALTER DATABASE [LoT] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [LoT]; END"
  ```

- **Linux (bash):** identical to macOS example (same container path `/opt/mssql-tools18/bin/sqlcmd`).

- **Container status:** if `docker exec mssql ...` fails with “No such container” or similar, start containers first (e.g., `make start` or the OS-specific start scripts).

### Export BACPAC from Azure (to create the backup you import)

- **Portal:**
  - Azure Portal → SQL databases → select your DB → top toolbar “Export”.
  - Choose a storage account + container + filename, and provide SQL admin credentials.
  - After export completes, download the `.bacpac` and place it under `backup/` locally (or anywhere, then use an absolute path on import).

- **Azure CLI:**
  ```bash
  az sql db export \
    --name <DB_NAME> \
    --server <AZURE_SQL_SERVER_NAME> \
    --resource-group <RESOURCE_GROUP> \
    --admin-user <SQL_ADMIN_USERNAME> \
    --admin-password '<SQL_ADMIN_PASSWORD>' \
    --storage-key-type StorageAccessKey \
    --storage-key '<STORAGE_ACCOUNT_KEY>' \
    --storage-uri 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/<CONTAINER>/<FILE>.bacpac'
  ```

  - Ensure the destination container exists and your credentials are valid.
  - Prefer short-lived credentials; do not commit secrets to the repo.
  - If your server uses Entra ID (AAD) admin, either set a SQL admin password for export or use tooling that supports AAD auth.

---

## Windows

### Prerequisites
- Docker Desktop for Windows
- .NET 8+ SDK from https://dotnet.microsoft.com/download
- PowerShell 7+ recommended
- Trust HTTPS developer certs (one-time):
  - Open PowerShell as Administrator: `dotnet dev-certs https --trust`
- AzCopy (for blob sync): install via Storage Explorer or standalone
- Azure CLI (for SAS generation and verification): https://learn.microsoft.com/cli/azure/install-azure-cli

### Using helper scripts (PowerShell)
Note: For database setup choices (migrations vs. Azure backup import), see: [Local database options: migrations vs. Azure backup](#local-database-options-migrations-vs-azure-backup-recommended-paths).
Scripts live in `be-scripts/windows/`.

- Start everything (infra → API):
```powershell
./be-scripts/windows/Start.ps1
```
- Fresh start (stop/clean → infra → migrations → API):
```powershell
./be-scripts/windows/Fresh-Start.ps1
```
- Stop only (stop containers, free ports):
```powershell
./be-scripts/windows/Stop.ps1
```
- Clean up (stop + remove containers):
```powershell
./be-scripts/windows/Clean-Up.ps1
```
- Start containers only (ensure DB exists):
```powershell
./be-scripts/windows/Start-Containers.ps1
```
- Apply DB migrations only:
```powershell
./be-scripts/windows/Run-Migrations.ps1
```
- Run the API only:
```powershell
./be-scripts/windows/Start-Api.ps1
```

Optional: seed Azurite blob storage with real data (see [AZURITE_SYNC.md](./AZURITE_SYNC.md) for details):
```powershell
./be-scripts/windows/Seed-Azurite.ps1
```

Verify:
- Open https://localhost:7057/swagger in your browser
- Or run: `curl -k https://localhost:7057/api/test`

---

## Linux

### Prerequisites
- Docker Engine
- .NET 8+ SDK and runtime from your distro or Microsoft packages
- Trust certs: platform-dependent (you can skip trust and use `-k` with curl)

### Using helper scripts
Note: For database setup choices (migrations vs. Azure backup import), see: [Local database options: migrations vs. Azure backup](#local-database-options-migrations-vs-azure-backup-recommended-paths).
Scripts live in `be-scripts/linux/`. Make them executable once:
```bash
chmod +x be-scripts/linux/*.sh
```

- Start everything (infra → API):
```bash
be-scripts/linux/start.sh
```
- Fresh start (stop/clean → infra → migrations → API):
```bash
be-scripts/linux/fresh_start.sh
```
- Stop only (stop containers, free ports):
```bash
be-scripts/linux/stop.sh
```
- Clean up (stop + remove containers):
```bash
be-scripts/linux/clean_up.sh
```
- Apply DB migrations:
```bash
be-scripts/linux/run_migrations.sh
```
- Run the API:
```bash
be-scripts/linux/start_api.sh
```

Optional: seed Azurite blob storage with real data (see [AZURITE_SYNC.md](./AZURITE_SYNC.md) for details):
```bash
be-scripts/linux/seed_azurite.sh
```

Makefile (OS-aware): you can also use the unified targets and Make will route to macOS, Linux, or Windows scripts automatically (Windows requires PowerShell 7 `pwsh` in PATH).
```bash
make start
make fresh
make stop
make migrate
make clean
make seed-azurite
```

Verify:
```bash
xdg-open https://localhost:7057/swagger || true
curl -k https://localhost:7057/api/test
```

---

## Notes and Troubleshooting

- **SQL login:**
  - The repo uses SA password `LoT_StrongP@ssw0rd1` out of the box.
  - Example connection string in `appsettings.Development.json`:
    `Server=localhost,1433;Database=LoT;User Id=sa;Password=LoT_StrongP@ssw0rd1;MultipleActiveResultSets=true;TrustServerCertificate=True`
  - If you change the SA password, update both appsettings and scripts accordingly.

- Migrations authentication:
  - `LoT.DataMigrations.Api` is protected with Basic auth; `Run-Migrations` scripts already include the header from `LoT.DataMigrations.Api/appsettings.Development.json`.

- Blob storage:
  - Azurite must be running. API blob config points to `UseDevelopmentStorage=true` and `http://127.0.0.1:10000/devstoreaccount1`.

- HTTPS trust:
  - If browsers or curl complain about certificates, ensure `dotnet dev-certs https --trust` was run (or use `curl -k`).

- .NET SDK pin:
  - The repo pins SDK `8.0.413` in `global.json`. Install `dotnet-sdk@8` to match; no extra PATH or DOTNET_ROOT exports are required on macOS.

- Test endpoint:
  - `GET https://localhost:7057/api/test` validates DB connection, a blob upload/delete cycle, and email sending.

---

## Quick start (macOS example)
```zsh
# 1) Prereqs (one-time)
brew install --cask dotnet-sdk@8
dotnet dev-certs https --trust

# 2) Start everything
be-scripts/mac/start.sh

# Alternative: Fresh start if you want a clean slate
be-scripts/mac/fresh_start.sh

# Verify
open https://localhost:7057/swagger
```
