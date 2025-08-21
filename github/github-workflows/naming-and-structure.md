# Naming and Structure (CTO Edition)

[← Back to Workflows README](README.md)

<a id="top"></a>

- Quick links: [Senior/Concise](#senior) • [Expanded/Practical](#expanded) • [Step-by-Step](#step-by-step)

---

<a id="senior"></a>
## 1) Senior/Concise

- UI/manual workflows (few, obvious): Start Release, Promote Release, Hotfix to Prod.
- Logic lives in reusable workflows: `_build-reusable.yml`, `_deploy-reusable.yml`.
- Automated/hidden flows may exist but are not required for core release.
- Use underscore prefix `_` for internal/reusable to keep UI clean.

[Back to top](#top)

---

<a id="expanded"></a>
## 2) Expanded/Practical

### File Layout
- UI/manual (visible):
  - [Start Release](../../../.github/workflows/start-release.yml)
  - [Promote Release](../../../.github/workflows/promote-release.yml)
  - [Hotfix to Prod](../../../.github/workflows/hotfix-to-prod.yml)
- Reusable (hidden):
  - [Build (reusable)](../../../.github/workflows/_build-reusable.yml)
  - [Deploy (reusable)](../../../.github/workflows/_deploy-reusable.yml)

### Referencing Reusable Workflows
Use relative references and explicit inputs/outputs.

```yaml
jobs:
  build:
    uses: ./.github/workflows/_build-reusable.yml
    with:
      environment: staging|prod|dev|test
      ref: ''
      branch: ${{ github.ref_name }}
      node_version: '20'
```

### Conventions
- Keep inputs typed and validated.
- Return outputs (e.g., resolved refs) for downstream jobs.
- Use concurrency groups and environment approvals for safety.

[Back to top](#top)

---

<a id="step-by-step"></a>
## 3) Step-by-Step

1. Create a new user-facing workflow in `.github/workflows/` without leading underscore.
2. For any non-trivial logic, create a corresponding `_name-reusable.yml` and call it via `uses:`.
3. Add `permissions:` explicitly; default to least privilege.
4. Add `concurrency:` and `environment:` to critical jobs to enforce gates.
5. Keep job names descriptive and stable for auditability.

[Back to top](#top)
