---
description: Cutover plan, verification, and rollback strategy when migrating from Bitbucket to GitHub
---

# GitHub Cutover and Rollback Plan

> [← Back to Docs Index](./README.md)

## TL;DR
- Freeze window announced; repo set read-only on Bitbucket.
- Mirror push to new GitHub repo; verify refs, LFS, submodules.
- Switch remote in working copies; reopen PRs against GitHub.
- Post-cutover verification checklist; archive Bitbucket; set redirects.
- Rollback: reopen Bitbucket, switch remotes back, document delta.

## 1) Prepare and Freeze
- Announce freeze, timebox, and owners.
- Bitbucket: set repo to read-only or communicate no-push policy.
- Inventory: pipelines, secrets, webhooks, integrations, releases.

See also:
- [Post‑Migration GitHub Setup](./github-post-migration-setup.md)
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)

## 2) Cutover Steps
- Mirror clone and push (branches, tags, notes, LFS, submodules).
- Configure repo defaults, protections, CODEOWNERS, environments.
- Recreate integrations (Slack, CI, deploy), migrate secrets.

Related:
- [GitHub Integrations Migration](./github-integrations-migration.md)
- [Security Hardening](./github-security-hardening.md)

## 3) Verification Checklist
- Branches/tags match counts; default branch set.
- Actions workflows green on a test PR.
- Environments and secrets present; protected branches enforced.
- Submodules point to GitHub; LFS pulls fine.
- Webhooks/apps firing as expected.

## 4) Rollback Strategy
- Preconditions: Only if critical blockers; define max rollback window.
- Steps:
  - Reopen Bitbucket to writes.
  - Switch origin in working copies back to Bitbucket.
  - Revert DNS/links; pause GitHub workflows.
  - Document commit delta between GitHub and Bitbucket.
- Recovery: Fix blockers, reattempt cutover with lessons learned.

## 5) Post‑Cutover
- Archive Bitbucket repo or set read-only permanently.
- Set README badges/links to GitHub.
- Monitor Actions, secrets rotation, and access logs for a week.

---

## Examples

### Mirror-clone and push (branches, tags, notes)

```bash
git clone --mirror git@bitbucket.org:org/repo.git repo.git
cd repo.git

# Optional: verify remote refs
git for-each-ref --format='%(refname)'

git remote add github git@github.com:org/repo.git
git push --mirror github

# If using LFS, run from a non-mirror clone:
# git lfs fetch --all && git lfs push --all github
```

### Post-cutover verification (quick checklist)

```txt
[ ] Default branch set to main
[ ] Branches/tags counts match Bitbucket
[ ] LFS files pull correctly
[ ] Submodules point to GitHub
[ ] Workflows green on sample PR
[ ] Protected branches enforced
[ ] Webhooks/apps receive events
```

