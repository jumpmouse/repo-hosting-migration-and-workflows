# Build and Deploy (03 Build and Deploy)

Source YAML: ../../../.github/workflows/build-and-deploy.yml

## Purpose
Manual wrapper to run the reusable build step for any environment/ref. Deploy functionality has been removed; use Promote Release for production deployments.

## Trigger
- workflow_dispatch with inputs `environment`, `ref`, `branch`, `build` (bool), `deploy` (bool)

## Jobs and Logic
- build_real (reusable)
  - If `inputs.build == true`, calls `./_build-reusable.yml` with provided inputs.

- build_skip
  - If `inputs.build == false`, echo skip.

## Notes
- Use this for ad-hoc rebuilds or re-deploys from a specific tag/branch.
- Node version standardized to 20 via build reusable.

## Related
- Build reusable: ./_build-reusable.md
- Promote Release: ./promote-release.md
