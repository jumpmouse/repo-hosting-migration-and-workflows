# GitHub Workflows Guide
  
  [← Back to Topics](../README.md)
  
  This guide documents how our GitHub Actions workflows are organized, named, and used across this repository. It explains manual (UI-triggered) workflows, reusable/internal workflows, and automated pipelines, along with environment protections, variables, and permissions.

## Workflow Model — Summary

### Branches and protections
- Long‑lived env branches: `dev`, `test`, `staging`, `prod1`, `prod2`.
- Release branches: `release/vX.Y.Z` (created from `test` by pipeline).
- `test` and `staging` are “locked”: only pipelines update them (no manual merges/pushes).

### Day‑to‑day development
- Feature branches → PR into `dev` (require 1 approval).
- Workflow [`_deploy-dev-test.yml`](../../../.github/workflows/_deploy-dev-test.yml) runs on `dev`/`test` pushes to test/lint/build/deploy to the matching environment.
- Workflow [`_sync-dev-to-test.yml`](../../../.github/workflows/_sync-dev-to-test.yml) auto‑syncs `test` to mirror `dev` on every `dev` push.
  - Attempts fast‑forward; if histories diverge, uses force‑with‑lease to mirror `dev` to `test`.

### Release creation to staging
- [`start-release.yml`](../../../.github/workflows/start-release.yml) (manual UI) creates `release/vX.Y.Z` from `test`, tags an RC, builds, and deploys to `staging`.
- Any push to `release/vX.Y.Z` (e.g., merging a `fix/...` PR) triggers [`_release-rc-on-push.yml`](../../../.github/workflows/_release-rc-on-push.yml):
  - Tags a new RC, builds, deploys to `staging`.
- Staging updates come only from `start-release` or RC pushes (no PR from `test` to `staging`).

### Promote to production
- [`promote-release.yml`](../../../.github/workflows/promote-release.yml) (manual UI) takes `release/vX.Y.Z`, creates final tag `vX.Y.Z`, creates a GitHub Release, builds, deploys to `prod1`/`prod2` (with approvals), then merges the release branch back into `main` (and may delete it).
  - This is the only path to contribute to `main`.

### Hotfixes
- [`hotfix-to-prod.yml`](../../../.github/workflows/hotfix-to-prod.yml) (manual UI) deploys a selected ref to `prod1`/`prod2`, creating a hotfix tag `vX.Y.Z+hotfix.N`.
- After a hotfix, cherry‑pick the fix back to `dev` (do not back‑merge into `staging`/`test`).

### Gates and safety
- Optional allowlists via variables: `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL`.
- `RELEASE_FREEZE` variable gates RC tagging and staging deploys.

This matches the intended strategy: release branch model; `dev` → `test` auto‑sync; `staging` only from release branch; promote to `prod1`/`prod2` via pipeline; merge back into `main` only via promote; hotfixes deployed manually and cherry‑picked to `dev`.
  
  ## Goals
  - Consistent naming and discoverability
  - Clear separation of user-facing vs internal/reusable workflows
  - Safe deployments with approvals and allowlists
  - Reproducible builds via reusable building blocks

## Workflow Types
- UI/manual workflows (visible in GitHub UI):
  - [Start Release](../../../.github/workflows/start-release.yml)
  - [Promote Release](../../../.github/workflows/promote-release.yml)
  - [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml)
  - [Build and Deploy](../../../.github/workflows/build-and-deploy.yml)
- Reusable/internal workflows (prefixed with `_` to reduce UI clutter):
  - [Build (reusable)](../../../.github/workflows/_build-reusable.yml)
  - [Deploy (reusable)](../../../.github/workflows/_deploy-reusable.yml)
  - [Test & Lint (reusable)](../../../.github/workflows/_test-lint-reusable.yml)
- Automated pipelines (also prefixed with `_`):
  - [Release RC on Push](../../../.github/workflows/_release-rc-on-push.yml)
  - [Deploy Dev/Test](../../../.github/workflows/_deploy-dev-test.yml)
  - [Sync Dev → Test](../../../.github/workflows/_sync-dev-to-test.yml)

Naming convention: all workflows not intended for direct UI triggering are prefixed with `_` and referenced via `uses: ./.github/workflows/_name.yml`.

## What to do in the GitHub UI
- Required (one-time per repo):
  - Configure Environments: `staging`, `prod1`, `prod2` (Settings → Environments), set required reviewers as needed.
  - Set repository/org Variables if used: `RELEASE_FREEZE`, `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL`.
- Optional (recommended):
  - Protect branches (e.g., `main`, `release/*`).
  - Configure environment secrets/variables per target.
  - Set up runners if using self-hosted.

## Default flow (Quick start)
1) Cut a release to staging
   - In GitHub → Actions → run [Start Release](../../../.github/workflows/start-release.yml)
   - Provide version (via branch `release/vX.Y.Z`), await environment approval for `staging`.
2) Promote to production
   - Run [Promote Release](../../../.github/workflows/promote-release.yml)
   - Select `release/vX.Y.Z`, choose targets (`prod1`, `prod2`, or both), approve environments.
3) Hotfix (when needed)
   - Run [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml) with a tag/SHA and targets.
4) Generic build+deploy
   - Run [Build and Deploy](../../../.github/workflows/build-and-deploy.yml) to build and deploy to any env.

Notes:
- If `RELEASE_FREEZE` is `'1'`, [Release RC on Push](../../../.github/workflows/_release-rc-on-push.yml) and staging deploy gates will block.
- Automated pipelines like [Deploy Dev/Test](../../../.github/workflows/_deploy-dev-test.yml) and [Sync Dev → Test](../../../.github/workflows/_sync-dev-to-test.yml) run based on branch events.
 - Promote Release operates on the `release/vX.Y.Z` branch as the source of truth (not on the `staging` branch).

## Reusable Workflows (Key Interfaces)
- Build
  ```yaml
  uses: ./.github/workflows/_build-reusable.yml
  with:
    ref: ''        # tag or SHA to build; empty means branch
    branch: ''     # branch to build when ref is empty
    node_version: '20'
  ```
- Deploy
  ```yaml
  uses: ./.github/workflows/_deploy-reusable.yml
  with:
    environment: staging|prod1|prod2|dev|test
    ref: ''
    branch: ''
  ```
- Test & Lint
  ```yaml
  uses: ./.github/workflows/_test-lint-reusable.yml
  with:
    ref: ''
    branch: ${{ github.ref_name }}
    node_version: '20'
  ```

See also: [Naming & Structure](./naming-and-structure.md) • [Reusable Workflows](./reusable-workflows.md) • [Release Flows](./release-flows.md) • [Environments & Permissions](./envs-and-permissions.md) • [Troubleshooting](./troubleshooting.md)

## Environment Protections & Variables
- Workflows depend on org/repo variables and environment protections.
- Example variables used:
  - `RELEASE_FREEZE` toggles release gates in `/_release-rc-on-push.yml`.
  - `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL` allowlist checks in deployment guards.
- Example concurrency:
  ```yaml
  concurrency:
    group: deploy-${{ github.ref_name }}
    cancel-in-progress: true
  ```

## Common Patterns
- Guard steps using `if: github.actor != 'github-actions'` to avoid loops.
- Use `needs:` to enforce build before deploy.
- Prefer tags for prod promotions; branches for staging.
- Inputs are validated via gates (manual approvals, allowlists, freeze flags).

## File Map
- UI/manual: [Start Release](../../../.github/workflows/start-release.yml), [Promote Release](../../../.github/workflows/promote-release.yml), [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml), [Build and Deploy](../../../.github/workflows/build-and-deploy.yml)
- Reusable: [Build (reusable)](../../../.github/workflows/_build-reusable.yml), [Deploy (reusable)](../../../.github/workflows/_deploy-reusable.yml), [Test & Lint (reusable)](../../../.github/workflows/_test-lint-reusable.yml)
- Automated: [Release RC on Push](../../../.github/workflows/_release-rc-on-push.yml), [Deploy Dev/Test](../../../.github/workflows/_deploy-dev-test.yml), [Sync Dev → Test](../../../.github/workflows/_sync-dev-to-test.yml)


---

> [← Back to Topics](../README.md)
