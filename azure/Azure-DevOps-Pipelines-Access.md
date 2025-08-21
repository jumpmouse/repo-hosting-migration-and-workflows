# Azure DevOps: Grant Access to Manage Pipelines (Step-by-step)

This guide explains how your client (or an existing Azure DevOps admin) should grant you rights to READ/UPDATE/ADD/DELETE pipelines, including required org/project access, repo rights (for YAML), service connections, and related resources.

Important: Azure DevOps permissions are separate from Azure subscription Owner. You need explicit access in the Azure DevOps organization and project.

## Required permissions (short version)
- Organization: add user in Organization settings > Users with Access level: Basic.
- Project: add user to Project Administrators (recommended for takeover). Least-privilege alternative: Contributors + explicit grants below.
- Pipelines (YAML/Classic): Allow View builds, Queue builds, Edit build pipeline, Delete build pipeline, Administer build permissions.
- Releases (Classic): in Pipelines > Releases > Security: Allow View/Edit/Delete/Administer.
- Repos (for YAML): Contribute, Create branch; respect branch policies; approve PRs as required.
- Service connections: grant User or Administrator on each connection; add user to Endpoint Creators to create new; consider “Grant access permission to all pipelines”.
- Library: Variable groups View/Edit/Manage; Secure files access if used.
- Environments: Manage/Create/Use and approval management if used.

## Which email should be added? How do I log in?
- If you already have a member account in the client tenant (a UPN like `firstname.lastname@clientdomain.com` or `@clienttenant.onmicrosoft.com`), ask them to add THAT address to Azure DevOps. You will sign in with this same UPN.
- If you want to use your external work email instead, they must invite that email to the Azure DevOps organization (and, if needed, to the tenant as a guest for any directory-bound actions). Then sign in with that external account.
- Consistency rule: the email they add in Azure DevOps must match the identity you’ll use to sign in.

Login steps
- Go to the org URL, e.g., `https://dev.azure.com/<org>`.
- Click Sign in and use the chosen identity (client UPN or your external account).
- If prompted, select the correct directory/tenant.
- After sign-in, you should see the project and pipelines once permissions are in place.

## Prerequisites
- Know the Azure DevOps organization URL (e.g., https://dev.azure.com/<org-name>) and target Project name.
- Someone with Azure DevOps Organization Administrator or Project Administrator permissions available to perform the steps below.
- If repos are in Bitbucket: you’ll also need access there and a service connection in Azure DevOps.

## 1) Add the user to the Azure DevOps organization
Performed by an Azure DevOps Organization Administrator.

- Go to Azure DevOps > Organization settings > Users > Add users.
- Email: <your-email>
- Access level: Basic (recommended; Stakeholder is too limited for pipeline edits).
- Add to group(s): leave empty for now (handled at project level) or add to a suitable org-level group if you have one.
- Add.


## 2) Add the user to the target Project and set base permissions
Performed by a Project Administrator.

- Open the Project > Project settings > Permissions.
- Add the user to one of:
  - Project Administrators (full rights in the project, easiest to start takeover), or
  - Contributors (then explicitly grant pipeline/repo/service connection permissions below).

Tip: Start with Project Administrators while you take over; later you can trim rights to least-privilege.


## 3) Grant pipeline permissions
Depending on pipeline type:

- YAML Pipelines (Pipelines > Pipelines):
  - Project-level permissions usually suffice when combined with repo write access.
  - Verify under Project settings > Permissions that the user/group has:
    - View builds, Queue builds
    - Edit build pipeline
    - Delete build pipeline
    - Administer build permissions (if you need to manage pipeline security)

- Classic Pipelines/Releases (UI-defined):
  - Pipelines > Pipelines > select pipeline > ... > Security: ensure your user/group has Allow for View/Edit/Delete/Administer.
  - Releases: Pipelines > Releases > select release definition > ... > Security: grant View/Edit/Delete/Administer.


## 4) Grant repository permissions (needed to edit YAML)
If pipelines are defined as YAML files in the repo, you need repo write access.

- Project settings > Repositories > Security > select repository.
- Ensure your user/group has:
  - Contribute (edit files)
  - Create branch
  - Bypass policies when pushing (optional, only if needed)
- Branch policies (Repos > Branches > select branch > Branch policies): review merge/approval requirements. Add yourself to the policy exceptions only if necessary.

Note: If the code is in Bitbucket, this step is done in Bitbucket (grant repo admin or at least write, plus Pipelines admin if Bitbucket Pipelines are used).


## 5) Service connections (deploy credentials)
Most deployments use a Service Connection (to Azure subscription, Bitbucket, GitHub, etc.). You need access to use and manage these.

- Project settings > Service connections:
  - For each connection used by pipelines, click it > Security:
    - Grant “User” or “Administrator” to your account.
    - Optionally, enable “Grant access permission to all pipelines” on the connection to avoid per-pipeline prompts.
  - If you will create new service connections, add your user to “Endpoint Creators” (Project settings > Permissions) or grant Project Administrator.


## 6) Variable groups, secure files, environments
- Library > Variable groups: open each group > Security: grant your user/group permissions (View/Edit/Manage).
- Pipelines > Library > Secure files: grant access if used.
- Pipelines > Environments: open environment > Security/Approvals: grant Manage/Create/Use permissions as needed.


## 7) If repositories are in Bitbucket
- Ask for Bitbucket workspace access (Admin on relevant repos).
- Verify/Configure CI integration:
  - If Azure DevOps pulls from Bitbucket: ensure a valid Bitbucket service connection exists (Project settings > Service connections) and you can manage it.
  - If Bitbucket Pipelines deploys: you need Bitbucket Pipelines permissions and access to variables/secrets.


## 8) Verification checklist
- Pipelines > Pipelines: you can see pipelines, create new, edit existing, queue runs, delete if needed.
- Pipelines > Releases (if used): you can edit stages, artifacts, and approvals.
- Repos: you can edit YAML and push branches (or approve PRs per policy).
- Project settings > Service connections: you can view and use the connections referenced by pipelines.
- Library: you can view/edit variable groups used by pipelines.
- Environments: you can view and manage approvals/resources.


## 9) Troubleshooting
- “Error fetching information” in Azure Portal Deployment Center:
  - You probably don’t have rights in the Azure DevOps org/project or the link is stale. Get added to the DevOps org, then refresh.
- Cannot edit pipeline YAML:
  - Check repo write permissions and branch policies. Ensure you’re not blocked by required reviewers or protected branches.
- Cannot use service connection:
  - You need to be granted permission on that connection or enable “Grant access permission to all pipelines.”
- Missing Classic Releases:
  - Classic Releases are not in this repo; look under Pipelines > Releases in Azure DevOps UI and grant Security there.


## Quick request template to send to the client
“Please add <your-email> to our Azure DevOps org <org-url> with access level Basic. In the project <project-name>, add me to Project Administrators. Also grant me access to Service connections, Variable groups, Environments, and Repos so I can view, create, edit, and delete pipelines as needed.”
