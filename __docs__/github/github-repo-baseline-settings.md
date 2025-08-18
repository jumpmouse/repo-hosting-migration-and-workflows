---
description: Opinionated baseline repo settings for GitHub — PRs, discussions, templates, branches, protections
---

# GitHub Repo Baseline Settings

> [← Back to Docs Index](./README.md)

## TL;DR
- Enable squash merges; auto-delete branches; optionally disable merge commits.
- Add PR/Issue templates; enable discussions if used.
- Define default branches and naming; configure protections per env.

## 1) PR Strategy
- Squash merges recommended; rebase optional; avoid merge commits for clarity.
 - If you enable "Require linear history" in branch protection, disable merge commits. Prefer Squash‑only for consistency.

## 2) Templates
- `.github/PULL_REQUEST_TEMPLATE.md` and `.github/ISSUE_TEMPLATE/*` for consistency.

## 3) Branching and Naming
- Default branch `main`; env branches `dev`, `test`, `staging`, `prod1`, `prod2`.
- Naming conventions for features/fixes/hotfixes.

## 4) Protections
- Apply rules per environment; include admins on higher envs.
- Map required status checks using the exact job names as they appear in workflow runs (e.g., `build`, `test`, `lint`, `typecheck`, `e2e`).
- Enable "Require review from Code Owners" so `.github/CODEOWNERS` entries are enforced on matching paths.

See also:
- [Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
- [Post‑Migration Setup](./github-post-migration-setup.md)

---

## Examples

### CODEOWNERS

```txt
# Require reviews from platform team for workflows and infra
.github/workflows/   @org/platform
infra/**            @org/platform

# App-specific ownership
apps/web/**         @org/web-team
apps/admin/**       @org/admin-team

# Shared packages
packages/**         @org/frontend
```

### Minimal PULL_REQUEST_TEMPLATE.md

```md
## Summary

## Testing
- [ ] Unit tests
- [ ] Integration tests (if applicable)

## Risks

## Checklist
- [ ] Follows coding standards
- [ ] Docs updated (if needed)
```

