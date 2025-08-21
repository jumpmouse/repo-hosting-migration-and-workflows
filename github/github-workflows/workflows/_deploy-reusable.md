# Deploy (Reusable)

Source YAML: ../../../.github/workflows/_deploy-reusable.yml

## Interface
- on: workflow_call
- inputs:
  - environment: dev|test|staging|prod (required). Used for environment gate and branch mapping.
  - ref: explicit tag/SHA (optional)
  - branch: branch when ref is empty (optional)
- outputs:
  - ref_to_deploy: resolved ref to deploy

## Logic
- Resolve ref or pick branch per environment (same mapping as build): dev→dev, test→test, staging→latest `release/v*`, prod→`uat3`.
- Validate allowlists:
  - `ALLOWED_DEPLOYERS_GLOBAL` and `ALLOWED_DEPLOYERS` (CSV) combined; actor must be in either if any are set.
- Placeholder deploy step prints selected ref and environment; replace with real deployment command.

## Example selection
```bash
if [ -n "$REF" ]; then echo ref_to_deploy=$REF; fi
# else map $ENV to branch and emit origin/$BRANCH
```

## Related
- Build reusable: ./_build-reusable.md
- Build and Deploy: ./build-and-deploy.md
