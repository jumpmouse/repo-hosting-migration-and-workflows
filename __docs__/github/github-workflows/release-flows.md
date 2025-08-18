# Release Flows

[← Back to Workflows README](./README.md)

This document explains the end-to-end release and hotfix flows driven by UI/manual workflows, and how they compose with reusable workflows.

## Start Release (staging cut)
Workflow: [Start Release](../../../.github/workflows/start-release.yml)

Purpose: Create a release branch `release/vX.Y.Z`, tag pre-release if needed, build and deploy to `staging`.

Key steps:
- Validate actor (optional allowlist)
- Create release branch and initial tag(s)
- Build for staging via `_build-reusable.yml`
- Deploy to staging via `_deploy-reusable.yml`

Inputs/Outputs:
- Inputs: version info (implicitly embedded in branch name), approvals via environment
- Outputs: branch name for subsequent jobs (e.g., deploy)

## Promote Release (to prod1/prod2)
Workflow: [Promote Release](../../../.github/workflows/promote-release.yml)

Purpose: From a release branch, compute final tag `vX.Y.Z`, create GitHub Release, build and deploy to prod targets.

Key steps:
- Tag computation from `release/vX.Y.Z`
- Create Release via `softprops/action-gh-release`
- Build for each target via `_build-reusable.yml`
- Deploy to each target via `_deploy-reusable.yml`
- Optional merge-back steps

Inputs:
- `release_branch`: release branch name
- `targets`: `prod1`, `prod2`, or `both`

## Hotfix to Prod
Workflow: [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml)

Purpose: Hotfix from selected ref (tag or SHA) directly to `prod1` and/or `prod2`.

Key steps:
- Resolve ref (tag or SHA)
- Tag hotfix (e.g., `vX.Y.Z+hotfix.N`)
- Build once via `_build-reusable.yml`
- Deploy to selected prod target(s) via `_deploy-reusable.yml`

Inputs:
- `target`: `prod1`, `prod2`, `both`
- `ref_type`/`ref_value`: source reference

## Build and Deploy (generic)
Workflow: [Build and Deploy](../../../.github/workflows/build-and-deploy.yml)

Purpose: Manually run a build and deploy to any environment, optionally skipping build.

Inputs:
- `environment`: `dev|test|staging|prod1|prod2`
- `ref`: tag or SHA (optional)
- `branch`: used if `ref` empty
- `build`: boolean to execute build step

Behavior:
- If `build` true, run `_build-reusable.yml`; else skip
- Deploy via `_deploy-reusable.yml` if build succeeded or skipped
