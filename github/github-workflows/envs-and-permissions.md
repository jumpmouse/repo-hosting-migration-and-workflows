# Environments & Permissions (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- Environments in play: `dev`, `test`, `staging`, `uat3` (gate), `prod` (deploy job env when promoting/hotfixing).
- Gate approvals: `Start Release` and `Hotfix to Prod` gate on `uat3`. `Promote Release` has no mid-flow gate; optionally wire a pre-tag `gate-release` on `uat3` if desired.
- Deploy jobs use the input environment; callers pass `staging` or `prod`.
- To keep a single approver group for prod, either:
  - Configure `prod` environment with the same reviewers as `uat3`, or
  - Call deploy with `environment: uat3` for prod.
- Variables: `ALLOWED_RELEASE_STARTERS`, `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL`, `RELEASE_FREEZE`.
- Permissions: minimal by default; elevate to `contents: write` where tagging/releases occur.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

### Environment configuration
- In Settings → Environments, define:
  - `staging`: required reviewers, env secrets.
  - `uat3`: approver group for gating Start/Promote/Hotfix.
  - `prod`: if you pass `environment: prod` to deploy, ensure reviewers match your governance (can be same as `uat3` if you want a single group).

### Permissions per workflow
- Start Release, Promote Release, Hotfix to Prod set `permissions: contents: write` to allow tag/merge operations.
- Reusable workflows keep `contents: read`.

### Variables and allowlists
- `ALLOWED_RELEASE_STARTERS`: optional allowlist for starting releases.
- `ALLOWED_DEPLOYERS` and `ALLOWED_DEPLOYERS_GLOBAL`: combined allowlist enforced in `_deploy-reusable.yml`.
- `RELEASE_FREEZE`: Promote toggles this flag (best-effort) before/after to signal freeze.

### Concurrency
- Use `concurrency.group` per workflow to prevent overlapping runs targeting same lane.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

1. Create/verify environments in Settings → Environments: `staging`, `uat3`, (optionally) `prod`.
2. Assign required reviewers and secrets to each.
3. Define repository variables if used:
   - `ALLOWED_RELEASE_STARTERS`
   - `ALLOWED_DEPLOYERS`, `ALLOWED_DEPLOYERS_GLOBAL`
   - `RELEASE_FREEZE`
4. Review branch protection as needed for `main`, `test`, and `release/*`.
5. Validate that approvals appear in Actions when running Start/Promote/Hotfix.

[Back to top](#top)
