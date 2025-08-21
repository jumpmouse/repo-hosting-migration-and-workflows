# Hotfix to Prod (04 Hotfix to Prod)

Source YAML: ../../../.github/workflows/hotfix-to-prod.yml

## Purpose
Deploy an urgent fix to production by tagging a hotfix from a chosen ref and running build+deploy.

## Trigger
- workflow_dispatch with input:
  - source_ref: optional tag/branch/SHA; defaults to `origin/uat3`.

## Permissions and Concurrency
- permissions: contents: write
- concurrency: group `hotfix-prod`

## Jobs and Logic
- guard-allowlist
  - Optional allowlist via `ALLOWED_DEPLOYERS`.

- resolve-ref
  - Determines commit to deploy; defaults to `origin/uat3` if `source_ref` empty.

- tag-hotfix
  - Finds nearest base `vX.Y.Z` tag and computes next `+hotfix.N`:
    ```bash
    BASE_TAG=$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' "$COMMIT" || true)
    NEXT=$(git tag -l "${BASE_TAG}+hotfix.*" | sed -E 's/.*\+hotfix\.([0-9]+)$/\1/' | sort -n | tail -n1)
    NEXT=${NEXT:+$((NEXT+1))}
    ```
  - Creates annotated tag and pushes.

- gate-prod
  - environment: `uat3` to reuse prod approver group.

- build / deploy (reusable)
  - Build + Deploy using `environment: prod`, `ref: hotfix tag`.

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
- Promote Release: ./promote-release.md
