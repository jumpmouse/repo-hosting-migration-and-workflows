# Build (Reusable)

Source YAML: ../../../.github/workflows/_build-reusable.yml

## Interface
- on: workflow_call
- inputs:
  - environment: dev|test|staging|production (required)
  - ref: explicit tag/SHA (optional)
  - branch: branch when ref is empty (optional)
  - node_version: default 20
- outputs:
  - built_ref: resolved ref that was built

## Logic
- Resolve ref to build:
  ```bash
  if [ -n "$REF" ]; then echo ref_to_build=$REF; exit; fi
  if [ -z "$BRANCH" ]; then
    case "$ENV" in
      dev) BRANCH=dev;;
      test) BRANCH=test;;
      staging) BRANCH=$(latest release/v* by SemVer);; 
      production) BRANCH=uat3;;
    esac
  fi
  echo ref_to_build=origin/$BRANCH
  ```
- Checkout detached at ref, setup Node `${{ inputs.node_version }}`, `npm ci`, `npm run build`.

## Notes
- Validates environment value and presence of `origin/<branch>`.
- Exposes `built_ref` to callers.

## Related
- Deploy reusable: ./_deploy-reusable.md
- Test/Lint reusable: ./_test-lint-reusable.md
