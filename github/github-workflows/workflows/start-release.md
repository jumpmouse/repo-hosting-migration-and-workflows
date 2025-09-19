# Start Release (01 Start Release)

Source YAML: ../../../.github/workflows/start-release.yml

## Purpose
Creates a release branch `release/vX.Y.Z` from `test` and tags the first RC `vX.Y.Z-rc.1`. No staging deploys.

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
  - environment: `production` requests approval from the production approver group.

- create-branch-and-tag
  - Computes target version and names (robust SemVer bump):
    ```bash
    # If inputs.version empty, compute next patch from latest clean vX.Y.Z
    LATEST=$(git tag --list 'v[0-9]*.[0-9]*.[0-9]*' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1 || true)
    if [ -z "$LATEST" ]; then VERSION="0.0.1"; else
      ver_no_v=${LATEST#v}; IFS='.' read -r MAJOR MINOR PATCH <<< "$ver_no_v"; PATCH=$((PATCH+1)); VERSION="$MAJOR.$MINOR.$PATCH"; fi
    ```
  - Branch `release/vX.Y.Z` is created from `base_ref` and pushed.
  - RC tag `vX.Y.Z-rc.1` is annotated and pushed.

  

## Approvals
- Only the gate on `production` is used.

## Notes
- Node 20 is standardized.
- Git identity uses `${{ github.actor }}` for traceability.

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
- Promote Release: ./promote-release.md
