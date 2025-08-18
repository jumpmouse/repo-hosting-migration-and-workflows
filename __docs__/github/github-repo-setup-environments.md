---
description: Step-by-step GitHub repository setup for multi-environment workflows (dev, test, staging, prod1, prod2)
---

# GitHub Repository Setup: Multi-Environment Workflow

> [← Back to Docs Index](./README.md)

## TL;DR (Quick Start)

- Create branches: `dev`, `test`, `staging`, `prod1`, `prod2`.
- Set branch protections per env (PRs, approvals, checks, restrict pushes on higher envs).
- Enable squash merges; add `.github/CODEOWNERS` with team ownership.
- Create GitHub Environments with secrets and required reviewers for higher envs.
- Map CI checks to required status checks; define promotion flow via PRs.

See also:
- [Post‑Migration GitHub Setup](./github-post-migration-setup.md)
- [GitHub Access Management](./github-access-management.md)
- [GitHub Workflows (CI/CD Pipelines) Guide](./github-workflows/README.md)

---

This guide defines a practical, step-by-step setup for 5 environments: `dev`, `test`, `staging`, `prod1`, `prod2`. It covers branches, protection rules, merge policies, environments, and CI/CD best practices.

---

## 1) Create Branches

1. From `main` (or initialize `main`):
   - Create long-lived branches: `dev`, `test`, `staging`, `prod1`, `prod2`.
2. Optional: create `release/*` as needed (e.g., `release/2025.08`).

Naming tips:
- Feature branches: `feat/<ticket-id>-short-desc`
- Fix branches: `fix/<ticket-id>-short-desc`
- Hotfix branches: `hotfix/<ticket-id>-short-desc`

---

## 2) Define Merge, Promotion, and Release Flows

This repo uses long‑lived environment branches (`dev`, `test`, `staging`, `prod1`, `prod2`) with CI/CD automation.

### A) Day‑to‑day development (Feature → Dev)
- [Manual] Open a PR from a feature branch to `dev`; pass checks and approvals.
- [Automatic] On merge to `dev`, CI runs and deployment to the `dev` environment executes via the build/deploy workflow.

### B) Test updates (pipeline‑only)
- [Automatic] `test` is kept in sync with `dev` by the `_sync-dev-to-test.yml` workflow on every push to `dev` (no PRs between `dev` and `test`).
- [Automatic] On updates to `test`, CI runs and auto‑deploys to the `test` environment.

### C) Release branch → Staging (pipeline‑only)
- [Manual] Cut a release using `start-release.yml` which creates `release/vX.Y.Z` from `test`, tags an RC, builds, and deploys to `staging` (with required approvals).
- [Automatic] Any push to `release/vX.Y.Z` (e.g., a small fix PR) triggers `_release-rc-on-push.yml` to tag a new RC, build, and deploy to `staging`.

### D) Production promotion (from release branch)
- [Manual] Run `promote-release.yml` on the selected `release/vX.Y.Z` branch to create the final tag and deploy to `prod1` and/or `prod2` (with required approvals).
- [Automatic] The workflow merges the release branch back into `main` and can delete the release branch.

### E) Hotfix flow (emergency production fix)
- [Manual] Create `hotfix/<ticket>` from the last production tag or the `prod1` baseline.
- [Manual] Run the "Hotfix to Prod" workflow targeting the hotfix branch.
  - [Automatic] The workflow builds/tests and deploys to `prod1` and then `prod2` with required approvals.
- [Manual] Cherry‑pick the hotfix commit(s) back to `dev` to realign forward development (no back‑merges to `staging`/`test`).

General rules:
- [Manual] Human PRs are for feature/fix branches into `dev`, and for small fixes into an active `release/vX.Y.Z` branch.
- [Automatic] Pipelines update `test` (auto‑sync from `dev`) and `staging` (from release branches). Avoid PRs between env branches for `test`/`staging`.
- [Policy] No circular/back‑merges between env branches. After production, the promote workflow merges release back into `main`. Hotfixes are cherry‑picked to `dev`.

---

## 3) Branch Protection Rules (per branch)

Repo → Settings → Branches → Add rule (repeat for each branch).

Recommended settings:
- Require a pull request before merging.
- Require reviews:
  - 1 approval for `dev`, `test`
  - 2 approvals for `staging`, `prod1`, `prod2`
- Require status checks to pass (use exact job names as they appear in workflow runs):
  - build, test, lint, typecheck, e2e (adjust to your repo)
- Require review from Code Owners (if `.github/CODEOWNERS` is used to gate critical areas).
- Require branches to be up to date before merging:
  - Recommended for `staging`, `prod1`, `prod2`
  - Optional for `dev`, `test`
- Include administrators: enabled for `staging`, `prod1`, `prod2`.
- Restrict who can push (direct):
  - Restrict direct pushes to `staging`, `prod1`, `prod2` (allow deploy bot/team only if needed).
- History policy:
  - Prefer "Squash merge only," or enable "Require linear history" (do not enable both).

Baseline policy by environment:
- `dev`: PR required, 1 approval, checks pass (build/test/lint/typecheck), optional up-to-date, direct push allowed for bots only (optional).
- `test`: PR required, 1 approval, checks pass, optional up-to-date.
- `staging`: PR required, 2 approvals, checks pass, CODEOWNERS (if used), require up-to-date, restrict direct push, include admins.
- `prod1`: PR required, 2 approvals, checks pass, require up-to-date, restrict direct push, include admins.
- `prod2`: PR required, 2 approvals, checks pass, require up-to-date, restrict direct push, include admins.

> Important: Lock `test` and `staging` to pipeline updates only. Do not open PRs into `test`, and do not merge directly into `staging`. These branches are updated solely by workflows: `_sync-dev-to-test.yml` (keeps `test` in sync with `dev`), `start-release.yml` and `_release-rc-on-push.yml` (update `staging` from `release/*`).

---

## 4) Repository Merge Strategy

Repo → Settings → General → Pull Requests.

- Enable: Squash merge.
- Optional: Disable merge commits; allow rebase only if your team prefers a linear history.
- If you enable "Require linear history" in branch protection, disable Merge commits. Prefer Squash-only for consistency.
- Auto-delete head branches on merge.

Reasoning: Squash keeps a clean history while preserving PR context.

---

## 5) CODEOWNERS

Create `.github/CODEOWNERS`:
```
# Require Tech Leads on critical paths
/docs/ @org/tech-leads
/apps/** @org/frontend
/infra/** @org/devops @org/tech-leads
```
Notes:
- Teams must exist (`org/tech-leads`, `org/frontend`).
- Enable branch protection option "Require review from Code Owners" to automatically request and enforce these teams on matching paths.

---

## 6) GitHub Environments and Secrets

Repo → Settings → Environments → New Environment for each: `dev`, `test`, `staging`, `prod1`, `prod2`.

For each environment:
- Add environment secrets (e.g., `API_URL`, `DEPLOY_TOKEN`).
- Optional protection rules: required reviewers for `staging`, `prod1`, `prod2` (e.g., `tech-leads`).
- Deployment branch policy: restrict to matching branch only (e.g., `staging` env → `staging` branch).

Workflow example snippet:
```yaml
jobs:
  deploy-staging:
    if: github.ref == 'refs/heads/staging'
    environment: staging
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./scripts/deploy.sh
        env:
          API_URL: ${{ secrets.API_URL }}
          DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
```

---

### 6a) Environment Variables, Repo Variables, and Workflow Inputs

Repository Variables (Repo → Settings → Secrets and variables → Actions → Variables):
- `ALLOWED_RELEASE_STARTERS` (optional, CSV of actors). Used in `start-release.yml` to guard who can start releases: `vars.ALLOWED_RELEASE_STARTERS`.
- `ALLOWED_DEPLOYERS` (optional, CSV of actors). Used in `promote-release.yml` and `hotfix-to-prod.yml` to guard who can deploy: `vars.ALLOWED_DEPLOYERS`.
- `RELEASE_FREEZE` ("0"/"1"). Best-effort flag set/unset by `promote-release.yml` via GitHub API as a release freeze signal.

Environment Secrets (per environment `dev`, `test`, `staging`, `prod1`, `prod2`):
- `API_URL`, `DEPLOY_TOKEN` (examples). Add any additional application secrets required by your deploy scripts.
- Required reviewers on environments gate deployments in `staging`, `prod1`, and `prod2`.

Workflow Inputs (UI-dispatched workflows):
- `start-release.yml`
  - `version` (optional SemVer; if empty, next patch is computed)
  - `base_ref` (defaults to `test`)
- `promote-release.yml`
  - `release_branch` (format: `release/vX.Y.Z`)
  - `targets` (`prod1` | `prod2` | `both`)
- `hotfix-to-prod.yml`
  - `target` (`prod1` | `prod2` | `both`)
  - `source_ref` (optional ref; defaults to target branch)
- `build-and-deploy.yml`
  - `environment` (`dev` | `test` | `staging` | `prod1` | `prod2`)
  - `ref` (optional tag/SHA)
  - `branch` (used if `ref` is empty)
  - `build` (boolean; default true)

Reusable workflow inputs:
- Build (`_build-reusable.yml`): `ref`, `branch`, `node_version` (default `20`).
- Deploy (`_deploy-reusable.yml`): expects `environment` and a ref/branch from caller.

## 7) CI Checks by Environment

- `dev`: lint, unit tests, typecheck, build.
- `test`: `dev` checks + integration tests.
- `staging`: `test` checks + deploy preview + smoke tests.
- `prod1`: production build, canary deploy, smoke tests.
- `prod2`: full production deploy, smoke tests, post-deploy checks.

Map these as required status checks in branch protection using the exact job names as they appear in workflow runs.

---

## 8) Releases and Versioning

- Final release tag is created by the "Promote Release" workflow from the `release/vX.Y.Z` branch (e.g., `v2025.08.17` or semver `v1.4.0`).
- Use GitHub Releases to publish notes and artifacts.
- Maintain `CHANGELOG.md`; generate release notes automatically via Actions if desired.

---

## 9) Hotfix Procedure

1. Branch from the highest env that needs the fix, typically `prod2`: `hotfix/<ticket>`.
2. Run the "Hotfix to Prod" workflow (builds, tags `vX.Y.Z+hotfix.N`, deploys to selected target(s) with required approvals).
3. Choose targets appropriately (both `prod1` and `prod2`, or one at a time as policy dictates) within the workflow approvals.
4. Cherry‑pick the hotfix commit(s) to `dev` to keep forward development in sync (do not back‑merge into `staging`/`test`).

---

## 10) Automation Tips

- Use labels + PR templates for feature PRs to `dev` and for small fixes into active `release/vX.Y.Z` branches (e.g., "Fix: release/v1.2.3").
- Use required reviewers for environments (Tech Leads).
- Use `actions/cache` keyed by lockfiles to speed CI.
- Configure branch protection APIs/`gh` scripts for reproducible setup.
- Use concurrency groups per branch/env to prevent overlapping deploys (see Workflows guide).

---

## 11) Step-by-Step Summary Checklist

1. Create branches: `dev`, `test`, `staging`, `prod1`, `prod2`.
2. Configure branch protection rules per section 3.
3. Set PR merge strategy (squash) and auto-delete branches.
4. Add `.github/CODEOWNERS` linking to `tech-leads` and `frontend` teams.
5. Create Environments and secrets for each environment.
6. Wire CI workflows with required checks per branch.
7. Define release tagging and notes process.
8. Document hotfix and promotion procedures in `CONTRIBUTING.md`.
9. Create repository variables as needed: `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS` (optional).
10. Configure required reviewers on `staging`, `prod1`, `prod2` environments.

---

> [← Back to Docs Index](./README.md)
