# Promote Release (02 Promote Release)

Source YAML: ../../../.github/workflows/promote-release.yml

## Purpose
Promote a prepared release branch `release/vX.Y.Z` to production:
- Compute and create final tag `vX.Y.Z` and GitHub Release
- Squash-merge the release into `uat3` (prod branch)
- Build and deploy to prod
- Merge back to `main`, delete the release branch, and clear freeze

## Trigger
- workflow_dispatch with input:
  - release_branch: e.g., `release/v1.2.3`

## Permissions and Concurrency
- permissions: contents: write, actions: write
- concurrency: group `promote-${{ inputs.release_branch }}`

## Jobs and Logic
- guard-allowlist
  - Optional allowlist via `ALLOWED_DEPLOYERS` (CSV usernames); skip if unset.

- gate-release (optional approval)
  - environment: `uat3` to keep a single approver group. Wire dependencies to enforce if desired.

- set-freeze / clear-freeze
  - Best-effort toggle of `RELEASE_FREEZE` repo variable using `gh api`.

- tag-and-release
  - Validates branch format and derives tag:
    ```bash
    BR="${{ inputs.release_branch }}"
    [[ $BR =~ ^release/v[0-9]+\.[0-9]+\.[0-9]+$ ]] || exit 1
    VER=${BR#release/}  # -> vX.Y.Z
    ```
  - Creates annotated tag and GitHub Release.

- sync-uat3
  - Squash-merges `release/vX.Y.Z` into `uat3`. Commits only if diff exists.

- build (reusable)
  - uses `./_build-reusable.yml` with `environment: prod`, `ref: tag`.

- deploy (reusable)
  - uses `./_deploy-reusable.yml` with `environment: prod`, `ref: tag`.

- merge-back-to-main / delete-release-branch
  - Merge release into `main` (signoff) and delete remote branch.

## Approvals
- Deploy job uses `environment: prod`. For a single approver group, either:
  - configure `prod` environment with same reviewers as `uat3`, or
  - pass `environment: uat3` to deploy.

## Notes
- Node 20 standardized in build step via reusable workflow.

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
- Start Release: ./start-release.md
- Hotfix: ./hotfix-to-prod.md
