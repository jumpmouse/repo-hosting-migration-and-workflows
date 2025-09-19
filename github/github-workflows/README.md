# GitHub Workflows Guide (CTO Edition)

[← Back to Topics](../README.md)

<a id="top"></a>

This is the authoritative guide to our GitHub Actions workflows. It documents how we cut releases, promote to production, and apply hotfixes, and how reusable building blocks are composed. It includes three tiers of explanations to suit different audiences.

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

See also: [Naming & Structure](./naming-and-structure.md) • [Reusable Workflows](./reusable-workflows.md) • [Release Flows](./release-flows.md) • [Environments & Permissions](./envs-and-permissions.md) • [Troubleshooting](./troubleshooting.md)

## Summary

- Branch model: `dev`, `test`, `release/vX.Y.Z`, `main`. The production branch is `uat3` (branch name only).
- Production deploys are driven from `release/vX.Y.Z` and finalized tags `vX.Y.Z`.
- Approvals use the GitHub Environment named `production`. Do not use `uat3` as an environment; it is the branch name for production.
- Reusable building blocks: `build-reusable.yml`, `deploy-reusable.yml`.
- Node.js 20 for builds.

Environments and approvals:
- Start/Promote/Hotfix gates use `environment: production` to request approval from the production reviewer group.
- Deploy jobs (via `deploy-reusable.yml`) set `environment: production` for production deployments.
- The production branch is `uat3`; workflows map the `production` environment to branch `uat3` where needed.

Concurrency:
- `start-release.yml`: `concurrency.group: start-release`.
- `promote-release.yml`: `concurrency.group: promote-${{ inputs.release_branch }}`.
- `hotfix-to-prod.yml`: `concurrency.group: hotfix-prod`.

Variables and allowlists:
- `ALLOWED_RELEASE_STARTERS` — optional allowlist for starting releases.
- `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL` — optional allowlists enforced in guards and reusable deploy.
- `RELEASE_FREEZE` — best-effort freeze flag toggled around promotion.

Key workflows (UI/manual):
- [Start Release](../../../.github/workflows/start-release.yml)
- [Promote Release](../../../.github/workflows/promote-release.yml)
- [Build and Deploy](../../../.github/workflows/build-and-deploy.yml)
- [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml)

Reusable/internal:
- [Build (reusable)](../../../.github/workflows/build-reusable.yml)
- [Deploy (reusable)](../../../.github/workflows/deploy-reusable.yml)

Documentation (per workflow):
- __UI/manual__
  - [Start Release](./workflows/start-release.md)
  - [Promote Release](./workflows/promote-release.md)
  - [Build and Deploy](./workflows/build-and-deploy.md)
  - [Hotfix to Prod](./workflows/hotfix-to-prod.md)
- __Push-triggered__
  - [Deploy Dev/Test](./workflows/_deploy-dev-test.md)
  - [Release RC on Push](./workflows/_release-rc-on-push.md)
  - [Sync Dev→Test](./workflows/_sync-dev-to-test.md)
- __Reusable/internal__
  - [Build (reusable)](./workflows/_build-reusable.md)
  - [Deploy (reusable)](./workflows/_deploy-reusable.md)
  - [Test & Lint (reusable)](./workflows/_test-lint-reusable.md)

---

<a id="senior"></a>
## 1) Senior/Concise

- Start Release → creates `release/vX.Y.Z` from `test`, tags RC. No staging deploys.
  - Approvals: `gate-start` on `production`.
- Promote Release → computes final `vX.Y.Z` from `release/vX.Y.Z`, creates GitHub Release, squash-merges into `uat3` (production branch), builds, deploys to production, merges back to `main`, cleans up branch, clears freeze.
  - Approvals: optional pre-tag `gate-release` on `production`.
- Hotfix to Production → picks ref (defaults to `origin/uat3`), tags `vX.Y.Z+hotfix.N`, builds, deploys.
  - Approvals: `gate-prod` on `production`.
- Reusable deploy resolves branches by env: dev→`dev`, test→`test`, staging→latest `release/v*`, production→`uat3`; if `ref` is set, it wins.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

- Start Release (`start-release.yml`)
  - Inputs: `version` (optional), `base_ref` (default `test`).
  - Jobs:
    - `guard-allowlist` (optional allowlist) → `gate-start` (env `production`) → `create-branch-and-tag`.

- Promote Release (`promote-release.yml`)
  - Inputs: `release_branch` (optional; auto-detects a single `release/*` if omitted).
  - Jobs:
    - `guard-allowlist` → `set-freeze` → `tag-and-release` (compute `vX.Y.Z`, tag and GitHub Release) → `sync-uat3` (squash from `release/vX.Y.Z`) → `build` (with `environment: production`, `ref: tag`) → `deploy` (with `environment: production`, `ref: tag`) → `merge-back-to-main` → `delete-release-branch` → `clear-freeze`.
  - Note: `gate-release` exists (env `production`). If you require approval before tagging, wire `set-freeze` or `tag-and-release` to depend on `gate-release`.

- Hotfix to Prod (`hotfix-to-prod.yml`)
  - Inputs: `source_ref` (optional); defaults to `origin/uat3`.
  - Jobs: `guard-allowlist` → `resolve-ref` → `tag-hotfix` → `gate-prod` (env `production`) → `build` (env `production`, `ref: hotfix tag`) → `deploy` (env `production`, `ref: hotfix tag`).

- Reusable Workflows
  - Build (`build-reusable.yml`): picks `ref` or resolves branch by env; checks out, sets up Node 20, `npm ci`, `npm run build`.
  - Deploy (`deploy-reusable.yml`): environment equals input; resolves `ref` or selects branch by env (production→`uat3`), allowlist gate, placeholder deploy step.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step (Runbooks)

- Start a release
  1. Actions → run Start Release.
  2. Provide `version` or leave blank to auto-bump; leave `baseref` as `test` unless directed.
  3. Approve `gate-start` in `production`.
  4. Wait for branch creation and RC tag.

- Promote to production
  1. Actions → run Promote Release.
  2. Select `release/vX.Y.Z` (or rely on auto-detect if exactly one exists).
  3. Approve `gate-release` if wired to block (optional, environment `production`).
  4. The workflow syncs `release/vX.Y.Z` into `uat3` via squash-merge.
  5. Build runs against `ref: vX.Y.Z`.
  6. Deploy runs with `environment: production`.
  7. After deploy, the workflow merges back to `main`, deletes the release branch, clears freeze.

- Hotfix deployment
  1. Actions → run Hotfix to Prod.
  2. Optionally provide `source_ref` (tag, branch, or SHA); leave empty to use `origin/uat3`.
  3. Approve `gate-prod` in `production`.
  4. Build and deploy proceed using the hotfix tag.

[Back to top](#top)
