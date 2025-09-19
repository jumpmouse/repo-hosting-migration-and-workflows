# Release Flows (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

Three tiers of guidance follow.

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- Start Release
  - Creates `release/vX.Y.Z` from `test`, tags RC. No staging deploys.
  - Approvals: `gate-start` via GitHub Environment `production`.

- Promote Release (to production)
  - From `release/vX.Y.Z`, compute final tag `vX.Y.Z` and create GitHub Release, squash-merge into the production branch `uat3`, build, deploy, merge back, delete branch, clear freeze.
  - Approvals: optional pre-tag `gate-release` (environment `production`). Deploy uses `environment: production`.

- Hotfix to Production
  - Resolve `source_ref` (default: `origin/uat3`), tag `vX.Y.Z+hotfix.N`, build and deploy to production.
  - Approvals via GitHub Environment `production` on gate.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

### Start Release
- Inputs: `version` (optional), `base_ref` (default `test`).
- Flow: allowlist → `gate-start` (environment: production) → create branch + RC tag.
- Purpose: prepare a release branch and RC tag.

### Promote Release
- Input: `release_branch` (optional; auto-detects single `release/*` if omitted).
- Flow: allowlist → set freeze → compute `vX.Y.Z` + GitHub Release → sync production branch `uat3` via squash from `release/vX.Y.Z` → build (`environment: production`, `ref: tag`) → deploy (`environment: production`, `ref: tag`) → merge back to `main` → delete release branch → clear freeze.
- Note: Optional `gate-release` exists; wire dependencies if you want pre-tag approval.

### Hotfix to Production
- Input: `source_ref` (optional).
- Flow: allowlist → resolve ref (default `origin/uat3`) → compute + push hotfix tag → `gate-prod` (environment: production) → build (`production`, tag) → deploy (`production`, tag).
- Purpose: urgent fixes to production while preserving release cadence.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

### Start Release
1. Run Start Release in Actions.
2. Provide `version` or leave blank; ensure `base_ref` is `test`.
3. Approve `gate-start` (environment: production).
4. Wait for branch + RC tag.

### Promote Release
1. Run Promote Release; select `release/vX.Y.Z` (or rely on auto-detect if exactly one release branch exists).
2. If wired, approve optional `gate-release` (environment: production).
3. Confirm tag `vX.Y.Z` and GitHub Release are created.
4. The workflow syncs `release/vX.Y.Z` into production branch `uat3` via squash-merge.
5. Build runs on the tag; deploy uses `environment: production`.
6. Post-deploy: merge back to `main`, branch deletion, freeze clear.

### Hotfix to Production
1. Run Hotfix to Production.
2. If needed, enter `source_ref`; else leave blank to use `origin/uat3`.
3. Approve `gate-prod` (environment: production).
4. Verify hotfix tag, build, deploy.

[Back to top](#top)
