# Test & Lint (Reusable)

Source YAML: ../../../.github/workflows/_test-lint-reusable.yml

## Interface
- on: workflow_call
- inputs:
  - ref: explicit tag/SHA (optional)
  - branch: branch when ref is empty (optional)
  - node_version: default 20
- outputs:
  - tested_ref: resolved ref used for testing

## Logic
- Resolve ref to test: prefer `ref`, else default branch or provided `branch`.
- Steps: checkout at ref → setup Node → `npm ci` → conditional `npm run lint` → `npm test -- --ci`.

## Snippets
```bash
if npm run | grep -qE '^\s*lint\s'; then npm run lint; else echo 'No lint script'; fi
```

## Related
- Build reusable: ./_build-reusable.md
- Deploy reusable: ./_deploy-reusable.md
