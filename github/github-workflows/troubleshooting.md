# Troubleshooting (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- Missing approval? Check the job `environment` matches your intended gate (`uat3` vs `prod`).
- Wrong ref? Verify `ref` vs branch resolution (prod→`uat3`, staging→latest `release/v*`).
- Tag conflicts? Re-runs are idempotent; ensure tags do not already exist.
- Allowlist denies? Confirm `ALLOWED_*` variables.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

- Double approvals
  - If you gate on `uat3` and deploy job uses `prod` with its own reviewers, you may see two approvals. Align env reviewers or use a single env.

- No approval requested
  - If deploy uses an environment without reviewers, it won’t pause. Add reviewers to that environment or gate earlier.

- Staging cannot resolve branch
  - Ensure at least one `release/vX.Y.Z` exists. Start a release if none.

- Prod branch mismatch
  - `_deploy-reusable.yml` and `_build-reusable.yml` resolve `prod` to `uat3` when no explicit `ref` is provided.

- GitHub Release/Tag errors
  - Ensure `permissions: contents: write` on workflows that tag or create releases.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

1. Approval didn’t show up
   - Inspect the job in Actions → confirm `environment` value.
   - If `prod`, confirm the `prod` environment exists and has reviewers; or switch caller to `environment: uat3`.

2. Deploy used wrong code
   - Check if `ref` was passed. If not, env-based branch selection applied.
   - For prod, confirm it resolved to `origin/uat3`.

3. Tag already exists
   - The job logs will indicate existing tag. Create a new version or increment hotfix.

4. Allowlist failures
   - Validate `ALLOWED_DEPLOYERS_GLOBAL` and `ALLOWED_DEPLOYERS` variable values.

[Back to top](#top)
