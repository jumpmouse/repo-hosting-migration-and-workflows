# Release Flows (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

Three tiers of guidance follow.

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- Start Release (staging cut)
  - Creates `release/vX.Y.Z` from `test`, tags RC, builds + deploys to `staging`.
  - Approvals: `gate-start` via `uat3`; `staging` environment on deploy.

- Promote Release (to prod)
  - From `release/vX.Y.Z`, compute final tag `vX.Y.Z` and create GitHub Release, squash-merge into `uat3` (prod), build, deploy, merge back, delete branch, clear freeze.
  - Approvals: no mid-flow gate. Optional pre-tag `gate-release` (env `uat3`). Deploy uses `environment: prod`.

- Hotfix to Prod
  - Resolve `source_ref` (default: `origin/uat3`), tag `vX.Y.Z+hotfix.N`, build and deploy to prod.
  - Approvals via `uat3` on gate; deploy uses `environment: prod`.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

### Start Release
- Inputs: `version` (optional), `base_ref` (default `test`).
- Flow: allowlist → `gate-start` (uat3) → create branch + RC tag → build (`staging`) → deploy (`staging`).
- Purpose: stabilize on `release/vX.Y.Z` and validate in `staging`.

### Promote Release
- Input: `release_branch`.
- Flow: allowlist → set freeze → compute `vX.Y.Z` + GitHub Release → sync `uat3` via squash from `release/vX.Y.Z` → build (`environment: prod`, `ref: tag`) → deploy (`environment: prod`, `ref: tag`) → merge back to `main` → delete release branch → clear freeze.
- Note: Optional `gate-release` exists; wire dependencies if you want pre-tag approval.
- Single approver group: configure `prod` env reviewers to match `uat3`, or pass `environment: uat3` to deploy.

### Hotfix to Prod
- Input: `source_ref` (optional).
- Flow: allowlist → resolve ref (default `origin/uat3`) → compute + push hotfix tag → `gate-prod` (uat3) → build (`prod`, tag) → deploy (`prod`, tag).
- Purpose: urgent fixes to prod while preserving release cadence.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

### Start Release
1. Run Start Release in Actions.
2. Provide `version` or leave blank; ensure `base_ref` is `test`.
3. Approve `gate-start` in `uat3`.
4. Wait for branch + RC tag.
5. Verify staging deploy succeeded.

### Promote Release
1. Run Promote Release; select `release/vX.Y.Z`.
2. If wired, approve optional `gate-release` in `uat3`.
3. Confirm tag `vX.Y.Z` and GitHub Release are created.
4. The workflow syncs `release/vX.Y.Z` into `uat3` via squash-merge.
5. Build runs on the tag; deploy uses `environment: prod`.
6. Post-deploy: merge back to `main`, branch deletion, freeze clear.

### Hotfix to Prod
1. Run Hotfix to Prod.
2. If needed, enter `source_ref`; else leave blank to use `origin/uat3`.
3. Approve `gate-prod` in `uat3`.
4. Verify hotfix tag, build, deploy.

[Back to top](#top)
