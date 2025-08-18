# Naming and Structure

[← Back to Workflows README](./README.md)

This document defines our conventions for organizing and naming GitHub Actions workflows.

## Principles
- Keep user-triggered workflows obvious and minimal.
- Encapsulate logic in reusable workflows to avoid duplication.
- Hide internal/automated pipelines from the UI with a leading underscore `_`.

## File Layout
- UI/manual (visible):
  - [Start Release](../../../.github/workflows/start-release.yml)
  - [Promote Release](../../../.github/workflows/promote-release.yml)
  - [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml)
  - [Build and Deploy](../../../.github/workflows/build-and-deploy.yml)
- Reusable building blocks (hidden):
  - [Build (reusable)](../../../.github/workflows/_build-reusable.yml)
  - [Deploy (reusable)](../../../.github/workflows/_deploy-reusable.yml)
  - [Test & Lint (reusable)](../../../.github/workflows/_test-lint-reusable.yml)
- Automated pipelines (hidden):
  - [Release RC on Push](../../../.github/workflows/_release-rc-on-push.yml)
  - [Deploy Dev/Test](../../../.github/workflows/_deploy-dev-test.yml)
  - [Sync Dev → Test](../../../.github/workflows/_sync-dev-to-test.yml)

## Referencing Reusable Workflows
Use relative references with the underscore prefix:

```yaml
jobs:
  build:
    uses: ./.github/workflows/_build-reusable.yml
    with:
      ref: ''
      branch: ${{ github.ref_name }}
      node_version: '20'
```

## Inputs and Outputs
- Prefer explicit, typed inputs for version, branch, environment.
- Return outputs from setup/tagging steps for downstream jobs.

## Concurrency and Idempotency
- Gate high-impact jobs with `environment` approvals.
- Use `concurrency.group` to prevent overlapping deploys per branch/env.
- Ensure re-runs are safe (re-push tags guarded, deploys idempotent).
