# Reusable Workflows (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- Build (`_build-reusable.yml`): resolves ref/branch by env; Node 20; `npm ci && npm run build`.
- Deploy (`_deploy-reusable.yml`): `environment` equals input; resolves ref/branch by env; allowlist check; placeholder deploy.
- Branch resolution baseline: dev→`dev`, test→`test`, staging→latest `release/v*`, prod→`uat3`.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

### Build interface
```yaml
uses: ./.github/workflows/_build-reusable.yml
with:
  environment: dev|test|staging|prod
  ref: ''        # tag/SHA
  branch: ''     # used when ref empty
  node_version: '20'
```
Behavior:
- Validates `environment` among dev/test/staging/prod.
- If `ref` provided, builds that commit/tag.
- Else, selects branch by env (staging: latest `release/v*`; prod: `uat3`).

### Deploy interface
```yaml
uses: ./.github/workflows/_deploy-reusable.yml
with:
  environment: dev|test|staging|prod
  ref: ''        # tag/SHA to deploy
  branch: ''     # used when ref empty
```
Behavior:
- Sets job `environment` to the provided value (approvals come from that environment).
- Resolves `ref` or selects branch by env (prod uses `uat3`).
- Combined allowlist: `ALLOWED_DEPLOYERS_GLOBAL` + `ALLOWED_DEPLOYERS`.

Single approver group for prod:
- Option A: Configure `prod` environment reviewers the same as `uat3`.
- Option B: Have callers pass `environment: uat3` for prod deploys.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

1. To build: call `_build-reusable.yml` with `ref` (tag) for prod promotions; with `branch` for staging.
2. To deploy: call `_deploy-reusable.yml` with the same `ref` used for build.
3. For prod, ensure the deploy job's `environment` matches your intended approver group (`prod` or `uat3`).
4. Keep allowlist variables current to avoid surprise failures.

[Back to top](#top)
