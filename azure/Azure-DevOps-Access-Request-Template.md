# Azure DevOps Access Request – Template

Subject: Request Azure DevOps access to manage pipelines for LoT project

Hi <Name>,

Please grant me access in Azure DevOps so I can take over CI/CD management for the LoT project. Details below.

Organization: <org-url>
Project: <project-name>
My account: <your-email>

Required access
- Organization
  - Add me in Organization settings > Users with Access level: Basic
- Project (preferred during takeover)
  - Add me to Project Administrators
  - (Least-privilege alternative: Contributors + explicit permissions below)
- Pipelines (YAML & Classic)
  - Allow: View builds, Queue builds, Edit build pipeline, Delete build pipeline, Administer build permissions
- Releases (Classic)
  - In Pipelines > Releases > Security: Allow View/Edit/Delete/Administer
- Repos (for YAML pipelines)
  - Contribute, Create branch (respect branch policies/PR approvals)
- Service connections (deploy creds & repo links)
  - Grant me User or Administrator on each connection used by pipelines
  - Add me to Endpoint Creators (to create new connections)
  - Consider enabling “Grant access permission to all pipelines” on connections
- Library & Environments
  - Variable groups: View/Edit/Manage; Secure files: access if used
  - Environments: Manage/Create/Use and approvals if used

Optional (GitHub cutover)
- Create/confirm a GitHub service connection via GitHub App to <github-org>/<repo>
- Ensure pipelines can select that connection and run

Thank you!
<Your Name>
<Your contact>
