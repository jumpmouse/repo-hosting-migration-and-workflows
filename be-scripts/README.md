# Backend Helper Scripts (be-scripts)

This folder contains cross-platform helper scripts to run the LoT backend locally. They are used directly or via the top-level Makefile targets (which auto-select OS-specific scripts).

- macOS scripts are under `be-scripts/mac/`
- Windows (PowerShell) scripts are under `be-scripts/windows/`
- Linux scripts are under `be-scripts/linux/`

Underscore-prefixed scripts (e.g., `_start_mssql.sh`) are internal helpers. Prefer the non-underscore scripts for day‑to‑day work.

## Common tasks (recommended entry points)

- Start everything (infra → API):
  - macOS: [`mac/start.sh`](./mac/start.sh)
  - Windows: [`windows/Start.ps1`](./windows/Start.ps1)
  - Linux: [`linux/start.sh`](./linux/start.sh)

- Fresh start (stop/clean → infra → migrations → API):
  - macOS: [`mac/fresh_start.sh`](./mac/fresh_start.sh)
  - Windows: [`windows/Fresh-Start.ps1`](./windows/Fresh-Start.ps1)
  - Linux: [`linux/fresh_start.sh`](./linux/fresh_start.sh)

- Start containers only (ensure DB exists):
  - macOS: [`mac/start_containers.sh`](./mac/start_containers.sh)
  - Windows: [`windows/Start-Containers.ps1`](./windows/Start-Containers.ps1)
  - Linux: [`linux/start_containers.sh`](./linux/start_containers.sh)

- Apply DB migrations:
  - macOS: [`mac/run_migrations.sh`](./mac/run_migrations.sh)
  - Windows: [`windows/Run-Migrations.ps1`](./windows/Run-Migrations.ps1)
  - Linux: [`linux/run_migrations.sh`](./linux/run_migrations.sh)

- Start the API only:
  - macOS: [`mac/start_api.sh`](./mac/start_api.sh)
  - Windows: [`windows/Start-Api.ps1`](./windows/Start-Api.ps1)
  - Linux: [`linux/start_api.sh`](./linux/start_api.sh)

- Stop and clean:
  - macOS: [`mac/stop.sh`](./mac/stop.sh), [`mac/clean_up.sh`](./mac/clean_up.sh)
  - Windows: [`windows/Stop.ps1`](./windows/Stop.ps1), [`windows/Clean-Up.ps1`](./windows/Clean-Up.ps1)
  - Linux: [`linux/stop.sh`](./linux/stop.sh), [`linux/clean_up.sh`](./linux/clean_up.sh)

- Seed Azurite (optional):
  - macOS: [`mac/seed_azurite.sh`](./mac/seed_azurite.sh)
  - Windows: [`windows/Seed-Azurite.ps1`](./windows/Seed-Azurite.ps1)
  - Linux: [`linux/seed_azurite.sh`](./linux/seed_azurite.sh)
  - Guide: [AZURITE_SYNC.md](../AZURITE_SYNC.md)

## Internal helpers (underscore-prefixed)

These are invoked by the public scripts above and generally should not be called directly:

- macOS/Linux:
  - `_start_mssql.sh`, `_start_azurite.sh`, `_create_db.sh`, `_run_containers.sh`, `_env_vars.sh`, `_clean.sh`
- Windows (PowerShell):
  - `_Start-Mssql.ps1`, `_Start-Azurite.ps1`, `_Create-Db.ps1`, `_Run-Containers.ps1`, `_EnvVars.ps1`, `_Clean.ps1`

## Makefile (alternative entry point)

At the backend repo root, you can use OS-aware targets that delegate into these scripts:

```bash
make start          # infra → API
make fresh          # stop/clean → infra → migrations → API
make migrate        # migrations only
make stop           # stop containers
make clean          # remove containers
make seed-azurite   # optional: blob sync helpers
make start_containers # containers only
make start_api      # API only
```

See also: [LOCAL_SETUP.md](../LOCAL_SETUP.md) for detailed setup and troubleshooting.
