# Azure DevOps: Switch Pipelines from Bitbucket to GitHub (Step-by-step)

Goal: after repo migration to GitHub, make Azure DevOps build/deploy from GitHub instead of Bitbucket. This guide assumes you already have Azure DevOps access and can manage pipelines, repos, service connections, and releases.


## Before you start
- You have access to the Azure DevOps organization/project and GitHub org/repo.
- GitHub repo contains the same code and pipeline YAMLs (e.g., under `devops/`).
- You know whether deployments are done by:
  - YAML pipelines (multi-stage), or
  - Classic Release pipelines (UI-defined) consuming a build artifact.

Tip: In your repo, current YAML in `devops/` builds and publishes artifacts (no deploy). Deployments are likely classic Releases that consume the build artifact. This guide covers both.


## 1) Create a GitHub service connection in Azure DevOps
- Who does this: Azure DevOps Project Administrator. Requires the GitHub org to have the Azure Pipelines app installed (next bullets).
- GitHub org owner/admin must first install the Azure Pipelines GitHub App for the organization:
  - Go to https://github.com/apps/azure-pipelines > Configure > choose the client’s GitHub organization (not a personal account) > select “Only select repositories” and pick the repo(s) to connect.
  - If the org enforces SSO: Org settings > Security > authorize the Azure Pipelines app for SSO.
  - If the org restricts third‑party apps: Org settings > Third‑party access > allow the Azure Pipelines app.
- In Azure DevOps: Project settings > Service connections > New > GitHub > GitHub App.
  - Sign in and ensure you pick the client’s GitHub organization and the correct repository.
  - Name the connection clearly (e.g., `github-lot`). Enable “Grant access permission to all pipelines.”
  - If your DevOps project requires approvals for new service connections, request approval from a Project Collection Administrator.
- Alternative (only if the org cannot install the App): choose GitHub (PAT) and use a token created by a GitHub org admin with repo + workflow scopes. Note: many orgs disallow PAT-based connections—App is recommended.


## 2) Create new pipelines pointing to GitHub (or rewire existing ones)
- Who does this: Azure DevOps Project Administrator.

Option A — Create new pipelines (simplest and safest):
- Pipelines > New pipeline > GitHub > select the org and repo (uses the service connection created in Step 1).
- Choose “Existing Azure Pipelines YAML file.”
- Pick the YAML path, e.g., `devops/devops_dev.yml`.
- Click Save & run. Repeat for `devops_test.yml`, `devops_uat2.yml`, `devops_uat3.yml`, `devops_pr.yml`.
- Advantage: clean history; old Bitbucket-linked pipelines can be retired later.

Option B — Rewire existing pipelines (keep same pipeline IDs):
- Pipelines > Pipelines > select pipeline > Edit > switch repository to the new GitHub service connection > select repo + default branch.
- Confirm the YAML path (e.g., `devops/devops_dev.yml`).
- Save. Run a validation build.


## 3) Fix triggers for GitHub
- Who does this: repository maintainer (you) with write access to the GitHub repo.
- Check each YAML under `devops/` for `trigger:` and `pr:` sections.
  - Update branch names to match the GitHub repo (e.g., `main` vs `master`, `dev`, `test`, `uat2`, `uat3`).
  - Commit changes via PR respecting branch protection rules.
- In the pipeline UI, ensure “Enable continuous integration” is on (if using classic settings overlay).
- Webhooks are created automatically by the GitHub App—no manual webhook setup is required.


## 4) Ensure the build still publishes the same artifact name
- Your template `devops/devops-template.yml` publishes an artifact named `drop`.
- If Classic Releases are used, keep the artifact name the same so releases continue to work.
- Run the pipeline once to publish a new artifact from GitHub.


## 5) Re-link Classic Release pipelines (if used)
- Pipelines > Releases > open the release definition.
- Artifacts (top):
  - If the artifact source is a specific build pipeline, keep it pointed to the same pipeline (even if repository changed to GitHub). Nothing else to change.
  - If it’s pointing to a repo (rare), change the artifact source to the new GitHub-connected build pipeline.
- Save.
- Create a release (or wait for trigger) and verify deployment.


## 6) Service connections for deployment
- If deployments use an Azure subscription service connection (ARM/SPN), no change is needed.
- If any step used a Bitbucket service connection (checkout or artifact), update that step to use the new GitHub connection.
- Project settings > Service connections: remove or disable old Bitbucket connection after cutover.


## 7) Variables, variable groups, and secrets
- Pipelines > Library > Variable groups: ensure the GitHub-based pipeline has permission to use them.
- If secrets were in Bitbucket pipelines (not in your case), recreate them in Azure DevOps Library or GitHub Actions (if migrating CI to GitHub Actions).


## 8) Disable Bitbucket triggers (cutover)
- In Bitbucket, protect or archive the old repo, or disable webhooks/pipelines.
- Communicate a cutover time; ensure no one pushes to the old repo.


## 9) Validate end-to-end
- Push a commit to each target branch (or use “Run pipeline” specifying the branch) and confirm:
  - Pipeline starts from GitHub.
  - Artifacts `drop` are produced.
  - Classic Release (if used) triggers or can be run manually and deploys FE/API/Migrations.
  - App Services show the new build version.


## 10) Clean up
- In Azure DevOps > Project settings > Service connections: remove old Bitbucket connection.
- In Azure Portal > App Service > Deployment Center: if it shows a stale Bitbucket/Azure DevOps link, click Disconnect, then optionally link to the correct pipeline.
- Retire old pipelines that still point to Bitbucket, or rename pipelines to clarify source.


## Quick cutover via Deployment Center to GitHub Actions
If you prefer to deploy with GitHub Actions (and not Azure DevOps), you can cut over directly from the App Service:
1. App Service > Deployment Center > Disconnect (removes the old link; does not stop DevOps pipelines by itself).
2. Click Set up > GitHub > authorize > select org/repo/branch.
3. Choose runtime/starter workflow; portal creates a `.github/workflows/*.yml` in your repo.
4. Configure publish method in the workflow:
  - Publish Profile: upload secret to GitHub (Settings > Secrets and variables > Actions) and reference it in the workflow.
  - Azure Login with Service Principal: create/reuse SPN and store credentials as GitHub secret.
5. Commit the workflow; Actions will run on push to the selected branch.
6. Validate deployment, then proceed to disable old Azure DevOps pipelines/releases (next section).

Notes:
- Deployment Center changes do not automatically disable Azure DevOps pipelines—disable them to avoid double-deploys.
- Keep artifact names and app settings consistent across systems during transition.


## Disable old Azure DevOps pipelines/releases safely
1. Pipelines > Pipelines: for each pipeline still pointing to Bitbucket or the old source:
  - Disable CI triggers (and schedules) in pipeline settings.
  - Optionally set the pipeline to Paused, or Delete only after full validation of GitHub path.
2. Pipelines > Releases (if used):
  - Edit each release definition and turn off continuous deployment triggers.
  - Retain the definition for history until you finalize the cutover, then delete/archive.
3. Project settings > Service connections:
  - Remove Bitbucket connections once nothing references them.
4. Azure Portal > App Service > Deployment Center:
  - Ensure it points to GitHub Actions (or leave disconnected if you manage via Azure DevOps only).
5. Monitor for double-deploys during the cutover window and adjust triggers accordingly.


## Notes and pitfalls
- Permissions: ensure you have repo write in GitHub and sufficient rights in Azure DevOps (Project Administrator + Service connections).
- Branch policies: GitHub protected branches may block pushes; use PRs as needed.
- YAML paths: confirm the same `devops/` paths exist in GitHub after the repo migration.
- Classic Releases: artifact must come from the same build pipeline definition; re-run a build after switching the pipeline’s repo.


## Quick checklist to send to client/DevOps admin
- Create GitHub service connection via GitHub App and grant access to the repo.
- Create new pipelines from GitHub using existing YAML files under `devops/`.
- Verify triggers and artifacts.
- Confirm Classic Release pipelines still pick artifacts from the same build pipeline.
- Disable Bitbucket and remove obsolete service connections.
