# Start Release (01 Start Release)

Source YAML: ../../../.github/workflows/start-release.yml

## Purpose
Creates a release branch `release/vX.Y.Z` from `test`, tags the first RC `vX.Y.Z-rc.1`, then builds and deploys to `staging` using reusable workflows.

## Trigger
- workflow_dispatch with inputs:
  - version: optional SemVer x.y.z. If empty, next patch from latest `v*` tag is computed.
  - base_ref: base branch to branch from (default `test`).

## Permissions and Concurrency
- permissions: contents: write (required for branch/tag ops).
- concurrency: group `start-release` (no cancel in progress).

## Jobs and Logic
- guard-allowlist
  - Optional allowlist via repo var `ALLOWED_RELEASE_STARTERS` (CSV usernames).
  - Skips if variable is not set.

- gate-start (environment approval)
  - environment: `uat3` ensures a single reviewer group approves starting a release.

- create-branch-and-tag
  - Computes target version and names:
    ```bash
    # If inputs.version empty, compute next patch from latest vX.Y.Z
    LATEST=$(git tag -l 'v[0-9]*.[0-9]*.[0-9]*' --sort=-v:refname | head -n1 || true)
    VERSION=${LATEST:+$(echo "$LATEST" | sed -E 's/^v([0-9]+)\.([0-9]+)\.([0-9]+)$/\1.\2.\3/')}
    # bump PATCH or default to 0.0.1
    ```
  - Branch `release/vX.Y.Z` is created from `base_ref` and pushed.
  - RC tag `vX.Y.Z-rc.1` is annotated and pushed.

- build-staging (reusable)
  - uses `./.github/workflows/_build-reusable.yml`
  - with: environment=staging, branch=`release/vX.Y.Z`, node_version=20.

- deploy-staging (reusable)
  - uses `./.github/workflows/_deploy-reusable.yml`
  - with: environment=staging, branch=`release/vX.Y.Z`.

## Approvals
- Only the gate on `uat3` is used; deploy job uses `staging` environment.

## Notes
- Node 20 is standardized.
- Git identity uses `${{ github.actor }}` for traceability.

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
- Promote Release: ./promote-release.md
