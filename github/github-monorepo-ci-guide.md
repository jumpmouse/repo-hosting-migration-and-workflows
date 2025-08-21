---
description: Monorepo CI patterns for GitHub Actions — path filters, matrices, caching, reusable workflows
---

# GitHub Monorepo CI Guide

> [← Back to Docs Index](./README.md)

## TL;DR
- Use path filters to run only affected jobs.
- Use matrix builds for apps/packages; share caches smartly.
- Use reusable workflows; enforce CODEOWNERS per folder.

## 1) Path Filters
- Limit jobs by `paths`/`paths-ignore` or `if: contains(github.event.pull_request.changed_files, ...)` with filters.
- For heavy jobs, add changed-path detection scripts.

## 2) Matrices
- Define per-app/package matrices; shard tests.
- Example dims: `app`, `node-version`, `os`.

## 3) Caching
- Cache per package with keys based on lockfiles; avoid cross-contamination.
- Docker layer caching via GHCR as needed.

## 4) Reusable Workflows
- Put common jobs in `.github/workflows/_*.yml` (underscore-prefixed) and call with `workflow_call`.
- See interfaces and inputs in [GitHub Workflows — Reusable Workflows](./github-workflows/reusable-workflows.md).

## 5) CODEOWNERS by Folder
- Use folder ownership to gate reviews and protect critical infra.

See also:
- [Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
- [Security Hardening](./github-security-hardening.md)

---

## Examples

### PR workflow with path filters, matrix, cache, and reusable call

```yaml
name: pr
on:
  pull_request:
    paths:
      - 'apps/**'
      - 'packages/**'
      - '!**/*.md'

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        app: [web, admin]
        node: [18, 20]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: ${{ matrix.node }} }
      - uses: actions/cache@v4
        with:
          path: |
            apps/${{ matrix.app }}/node_modules
          key: ${{ runner.os }}-npm-${{ matrix.node }}-${{ hashFiles('apps/' + matrix.app + '/package-lock.json') }}
      - run: npm ci --prefix apps/${{ matrix.app }}
      - run: npm test --prefix apps/${{ matrix.app }} -- --ci

  quality:
    uses: ./.github/workflows/_test-lint-reusable.yml
    with:
      # Provide inputs supported by the reusable workflow; see docs linked above.
      ref: ''
      branch: ${{ github.ref_name }}
```

