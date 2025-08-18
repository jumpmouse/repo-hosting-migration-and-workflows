# Reusable Workflows

[← Back to Workflows README](./README.md)

This doc explains our shared building blocks used across UI/manual and automated pipelines.

## [Build (reusable)](../../../.github/workflows/_build-reusable.yml)
Purpose: produce an artifact from a tag/commit or branch with a specific Node version.

Inputs:
- `ref` (string): Tag or SHA; if empty, `branch` is used.
- `branch` (string): Branch to build when `ref` is empty.
- `node_version` (string): Node.js major version (e.g., '20').

Notes:
- Intended to be idempotent; cache as appropriate; avoid secret leakage in logs.
- Outputs are consumed by deploy jobs (or shipped via artifact upload if needed).

## [Deploy (reusable)](../../../.github/workflows/_deploy-reusable.yml)
Purpose: deploy a previously built artifact (or perform build within deploy target) to an environment.

Inputs:
- `environment` (string): `dev`, `test`, `staging`, `prod1`, or `prod2`.
- `ref` (string): Tag or SHA; if empty, `branch` is used.
- `branch` (string): Branch to deploy when `ref` is empty.

Notes:
- Uses environment protection rules (manual approval) as configured in the repo.
- Can implement allowlist checks via repo/org variables.

## [Test & Lint (reusable)](../../../.github/workflows/_test-lint-reusable.yml)
Purpose: run unit tests and linting consistently before building or deploying.

Inputs:
- `ref`, `branch`, `node_version` similar to build workflow.

Notes:
- Designed for fast feedback and reproducibility across branches.

## How to Use
Example call from a job:
```yaml
jobs:
  build:
    uses: ./.github/workflows/_build-reusable.yml
    with:
      ref: ''
      branch: ${{ github.ref_name }}
      node_version: '20'
```

## Versioning and Changes
- Keep inputs backward compatible; add new inputs with sensible defaults.
- Document breaking changes here and in commit messages.
