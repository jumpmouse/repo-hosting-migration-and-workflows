---
description: Manual local migration from Bitbucket to GitHub with full history, pipelines conversion, releases, and secrets
---

# Bitbucket → GitHub: Manual Local Migration Guide

This guide shows how to migrate a repository from Bitbucket to GitHub while preserving full Git history, branches, tags, LFS, and submodules. It also covers pipelines (Bitbucket Pipelines → GitHub Actions), Releases transfer, and Secrets migration.

> [← Back to Docs Index](./README.md)

---

## Related Guides

- [GitHub Post‑Migration Setup](./github-post-migration-setup.md)
- [GitHub Access Management](./github-access-management.md)
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)

## TL;DR (End-to-End)

- Mirror clone from Bitbucket and push to GitHub (branches, tags, LFS, submodules).
- Switch remotes in working copies; verify refs and default branch.
- Convert Pipelines to Actions; configure environments, secrets, and required checks.
- Recreate releases and integrations; update badges/links.
- Apply protections, CODEOWNERS, and baseline repo settings.
- Run verification checklist; archive Bitbucket or set read-only.

## 1) Prerequisites

- **Access**: You can clone from Bitbucket and push to GitHub.
- **New GitHub repo**: Create an empty repo (no README/license initially).
- **Git LFS**: Install if your repo uses LFS.
- **SSH**: Prefer SSH URLs or ensure HTTPS tokens configured.

---

## 2) Mirror-Clone and Push (Preserves Full History)

```bash
# 1) Bare mirror clone from Bitbucket
git clone --mirror git@bitbucket.org:<team>/<repo>.git
cd <repo>.git

# 2) Add GitHub as a remote
git remote add github git@github.com:<org>/<repo>.git

# 3) Push all refs (branches, tags, notes)
git push --mirror github
```

> Important:
> - Ensure the target GitHub repository is empty before running `git push --mirror`.
> - After pushing, explicitly set the default branch in GitHub if it should differ from Bitbucket's default.

### If using Git LFS
```bash
git lfs fetch --all
git lfs push --all github
```

### If using submodules
- Migrate each submodule (mirror → push) similarly.
- Update `.gitmodules` to point to GitHub URLs and commit.
```bash
git submodule sync --recursive
git submodule update --init --recursive
# Edit .gitmodules to use GitHub URLs, then commit the change
```

### Post-push sanity checks
```bash
# Compare ref counts (optional)
git for-each-ref --format='%(refname)' | wc -l
# List tags
git tag
```
- On GitHub: set the default branch and protection rules to match Bitbucket.

### Update your working clones
```bash
# In your normal working copy (not the bare repo)
git remote set-url origin git@github.com:<org>/<repo>.git
git fetch --prune
```

---

## 3) Pipelines → GitHub Actions

High‑level steps to convert Bitbucket Pipelines to GitHub Actions:

- __Create workflows__: Move logic from `bitbucket-pipelines.yml` to `.github/workflows/*.yml`.
- __Map concepts__: triggers, jobs/steps, services, caches, artifacts, env/variables → Actions equivalents.
- __Define environments__: staging/prod, required reviewers, protected branches.
- __Configure checks__: required status checks and CODEOWNERS.
- __Migrate secrets__: replace `$BITBUCKET_*` with `${{ secrets.NAME }}`.

Details and templates are documented in:
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
- [GitHub Post‑Migration Setup](./github-post-migration-setup.md)

---

## 4) Releases Transfer (Tags, Release Notes, Assets)

Summary:

- __Tags__: Migrated by `git push --mirror`.
- __Releases__: Recreate key releases or automate from tags/CHANGELOG using Actions.
- __Assets__: Re‑upload Bitbucket downloads to GitHub Releases.

Recommended workflows and tagging strategy:
- [GitHub Post‑Migration Setup](./github-post-migration-setup.md) (sections 8–9)
- [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md) (sections 8–9)

---

## 5) Secrets Migration (Detailed)
Summary:

- __Inventory__: export Bitbucket variables; classify sensitive vs config.
- __Create__: add repo/org/environ­ment secrets in GitHub.
- __Replace references__: `$FOO` → `${{ secrets.FOO }}` in Actions.
- __Govern__: rotate, require reviewers, prefer OIDC for cloud.

Full guidance and checklists:
- [GitHub Post‑Migration Setup](./github-post-migration-setup.md) (sections 6–8)

---

## 6) Other Items to Recreate

Concise checklist:

- __Issues & PRs__: migrate or archive using tools/scripts.
- __Wiki__: mirror‑push Bitbucket wiki to GitHub wiki repo.
- __Branch protections__: required reviews, status checks, CODEOWNERS.
  - [GitHub Repo: Environments & Branch Protections](./github-repo-setup-environments.md)
  - [GitHub Post‑Migration Setup](./github-post-migration-setup.md)
- __Webhooks/Integrations__: re‑create third‑party hooks (CI, Slack, deploys).
- __Deployments__: map to GitHub Environments + secrets.
- __Access control__: org teams, repo roles, least‑privilege.
  - [GitHub Access Management](./github-access-management.md)
  - [GitHub Post‑Migration Setup](./github-post-migration-setup.md)
- __Badges/Docs__: update badges and contributor docs to GitHub URLs.

---

## 7) Verification Checklist

- **Commits/branches/tags** visible on GitHub and match counts.
- **Default branch** and protection configured.
- **Actions** workflows green on a test PR; required status checks mapped using the exact job names (e.g., `build`, `test`, `lint`, `typecheck`, `e2e`).
- **Secrets**: present and referenced correctly in workflows.
- **Environments**: required reviewers configured for `staging`, `prod1`, `prod2`; deployment branches restricted as needed.
- **Repository variables** (if guarding workflows): `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `RELEASE_FREEZE` created under Actions → Variables.
- **Submodules**: point to GitHub and update cleanly.
- **LFS**: assets download and build/test pass.

---

## 8) Quick Troubleshooting

- "shallow update not allowed": ensure you used `--mirror` (bare) clone.
- Missing tags/branches: verify `git push --mirror github` in the bare repo.
- LFS files as pointers: run `git lfs fetch --all` then `git lfs push --all github`.
- Actions not triggering: verify `on:` patterns and default branch name.
- Cache misses: ensure stable keys (lockfiles) and exact paths.

---

## Appendix: Safety Notes

- `git push --mirror` overwrites remote refs to match the local mirror. Use only on the new empty GitHub repo or after careful review.
- Prefer SSH keys or fine-scoped tokens.
- Keep Bitbucket repo read-only or archived until everything is verified.

---

> [← Back to Docs Index](./README.md)
