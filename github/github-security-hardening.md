---
description: Security hardening checklist for GitHub orgs and repos — secrets, scanning, protections, environments
---

# GitHub Security Hardening

> [← Back to Docs Index](./README.md)

## TL;DR
- Enforce org-wide 2FA/SSO; keep Owners small.
- Enable secret scanning, Dependabot alerts/updates, code scanning.
- Use environments with required reviewers; prefer OIDC to static cloud creds.

## 1) Organization Controls
- Enforce 2FA/SSO; audit members quarterly.
- Base permissions: None; require team-based access.

## 2) Repository Protections
- Branch protection rules with required checks and Code Owners.
- Map required status checks using the exact job names as they appear in workflow runs (e.g., `build`, `test`, `lint`, `typecheck`, `e2e`).
- Enable "Require review from Code Owners" so entries in `.github/CODEOWNERS` are enforced on matching paths.
- Signed commits and required linear history (optional strictness levels).

## 3) Secrets and Credentials
- Prefer OIDC to cloud providers; rotate any remaining static secrets.
- Use org/env secrets; restrict repo secrets; audit usage.

## 4) Scanning and Updates
- Enable secret scanning, Dependabot alerts, version updates PRs.
- Code scanning with default or language-appropriate analyzers.

## 5) Environments and Deployments
- Required reviewers for staging/prod envs; restrict deployment branches.
- Store only per-env secrets; avoid repo-level prod secrets.
 - Use environment protection to gate deployments (required reviewers) and keep prod deploys auditable.

See also:
- [Access Management](./github-access-management.md)
- [Post‑Migration Setup](./github-post-migration-setup.md)

---

## Examples

### Dependabot configuration (security + versions)

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: npm
    directory: '/'
    schedule: { interval: weekly }
    open-pull-requests-limit: 10
    labels: ['dependencies']
    allow: [{ dependency-type: 'direct' }]
    commit-message:
      prefix: 'deps'
  - package-ecosystem: github-actions
    directory: '/'
    schedule: { interval: weekly }
```

### Code scanning (default setup)

```yaml
name: code-scanning
on:
  push:
  pull_request:
  schedule:
    - cron: '0 2 * * 1'
jobs:
  analyze:
    uses: github/codeql-action/.github/workflows/codeql.yml@v3
```

