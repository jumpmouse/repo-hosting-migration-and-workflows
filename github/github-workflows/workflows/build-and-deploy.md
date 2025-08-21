# Build and Deploy (03 Build and Deploy)

Source YAML: ../../../.github/workflows/build-and-deploy.yml

## Purpose
Manual wrapper to run the reusable build and deploy steps for any environment/ref, with toggles to run-only-build or run-only-deploy.

## Trigger
- workflow_dispatch with inputs `environment`, `ref`, `branch`, `build` (bool), `deploy` (bool)

## Jobs and Logic
- build_real (reusable)
  - If `inputs.build == true`, calls `./_build-reusable.yml` with provided inputs.

- build_skip
  - If `inputs.build == false`, echo skip.

- deploy (reusable)
  - Runs when `inputs.deploy == true` and build either skipped or succeeded.
  - Calls `./_deploy-reusable.yml` with provided inputs.

## Notes
- Use this for ad-hoc rebuilds or re-deploys from a specific tag/branch.
- Node version standardized to 20 via build reusable.

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
