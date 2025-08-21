# Azure: Create a New Admin User (Step-by-step)

This guide is written for a developer taking over a client’s Azure environment. It explains how to get yourself into their tenant, what “admin” means, how scopes work, and exactly how to assign the right permissions.


## What does "admin" mean?
In Azure, "admin" typically means you can manage Azure resources (create/update/delete) and possibly grant access to others. Common choices:
- Owner at Subscription scope: full control over all resources, can grant access.
- Contributor at Subscription scope + User Access Administrator: can manage resources and grant access without full Owner rights.

Pick the least privilege that satisfies your needs. "Owner" is the simplest catch‑all, but broader.


## Scopes (what they are)
Azure RBAC permissions are assigned at a scope and inherit downwards:
- Subscription (top): affects all resource groups/resources in that subscription.
- Resource group: affects only resources in that group.
- Resource: affects only that single resource.

Rules of thumb:
- If you’re taking over the entire environment, assign at Subscription scope.
- If you only manage a specific project, assign at the target Resource group.
- Avoid mixing many overlapping assignments—prefer the narrowest scope that meets the need.


## Prerequisites
- Someone who is already an admin must add you first. You cannot add yourself to a tenant you’re not in.
- That person needs either:
  - Microsoft Entra role that can add users/invite guests (e.g., Global Administrator, User Administrator) and
  - Azure RBAC rights at the target scope to assign roles (Owner or User Access Administrator).

Who can help: client’s existing Subscription Owner, Tenant Global Admin, or the previous vendor if they still have access.

If no one can add you, see “Escalation paths” below.


## What is a UPN (User Principal Name)?
- The UPN is the sign-in name for an account in the client’s Microsoft Entra ID tenant.
- Format: username@tenant-domain (e.g., john.doe@contoso.com or john.doe@contoso.onmicrosoft.com).
- You won’t have a UPN in their tenant until they create a member account for you. Guests get an auto-generated UPN behind the scenes and sign in with their own email.


## You’re not in their tenant yet — how to get in
Ask an existing tenant admin to onboard you in one of two ways:
- Guest (B2B) invitation — fastest for external consultants
  - They go: Microsoft Entra ID > Users > New user > Invite external user, enter your email, send invite.
  - You accept the invite from your email. You’ll sign in with your existing work account.
  - They then assign you RBAC (e.g., Owner) at the correct scope.
- Member (internal) account — best for long-term ownership
  - They go: Microsoft Entra ID > Users > New user > Create new user, set your UPN (e.g., firstname.lastname@clientdomain.com or @<tenant>.onmicrosoft.com) and initial password.
  - You sign in using that UPN, change password on first login.
  - They then assign you RBAC at the correct scope.

Suggested request text you can send to the client admin:
- Option A (Guest): “Please invite me as a guest using <your-email> and assign me Owner at the Subscription scope so I can take over management.”
- Option B (Member): “Please create a member user for me (UPN suggestion: <firstname.lastname@clientdomain.com>), share the initial password securely, and assign me Owner at the Subscription scope.”


## 1) Create the user in Microsoft Entra ID
- Performed by an existing tenant admin in the Azure Portal.
- Navigate: Home > Microsoft Entra ID > Users > New user.

Choose one option:
- Create new user (member, internal):
  - Identity:
    - User principal name (UPN): your login (e.g., yourname@clienttenant.onmicrosoft.com or the client’s custom domain).
    - Name: your display name.
  - Password: auto-generate or set an initial password; note it securely.
  - Groups (optional now): can be left empty.
  - Directory roles (optional now): leave at “User” unless you also need tenant-level admin like Global Admin.
  - Usage location: set if needed for licensing policies.
  - Create.
- Invite external user (guest/B2B):
  - Email: your existing work email.
  - Display name and (optional) personal message.
  - Groups/Directory roles: usually leave empty here.
  - Send invite. Accept the invitation from the email you receive to complete onboarding.

Which to pick?
- Member (Create new user) becomes a native account in the client’s tenant. Best for long-term admins.
- Guest (Invite external user) keeps your identity in your home tenant. Best for external consultants. RBAC works the same for Azure resources.


## 2) Grant admin permissions via RBAC (Access control IAM)
Performed by someone who already has rights at the target scope.

Choose the target scope first:
- Subscription: Home > Subscriptions > select subscription
- Resource group: Home > Resource groups > select group
- Resource: open the resource

Then assign roles:
- Open Access control (IAM) in the left menu.
- Click Add > Add role assignment.
- Role tab: pick:
  - Owner (full control, can grant access), or
  - Contributor (manage resources) + User Access Administrator (to grant access)
- Members tab: Select members > search your user (or guest) > Select.
- Review + assign.

Tip: If you want the user to be a full admin for the entire subscription, assign Owner at the Subscription scope.


## 3) Verify and remove conflicting assignments
- Still in Access control (IAM), open Role assignments and search the user.
- Ensure they have the intended role(s) at the intended scope.
- Remove any unintended higher-privilege roles to avoid surprises.


## Directory roles vs Azure roles (important)
- Directory roles (Microsoft Entra ID): control tenant directory actions (e.g., manage users/apps). Examples: Global Administrator, User Administrator, Global Reader.
- Azure roles (RBAC): control Azure resource actions (e.g., VMs, Storage, App Services). Examples: Owner, Contributor, Reader, User Access Administrator.

You often only need Azure roles to manage resources. Ask for Entra directory roles only if you must manage identities, apps, or tenant settings.


## Billing vs RBAC scopes (who sees invoices)
- Billing roles are separate from Azure RBAC. If you need to manage billing/invoices:
  - Go to Cost Management + Billing > Billing profiles / Invoice sections.
  - Assign roles like Billing account reader, Billing profile owner as needed.
- Having Subscription Owner does not automatically grant billing access (and vice versa).


## Optional hardening
- Enforce MFA and conditional access (Microsoft Entra ID > Protection).
- Use Privileged Identity Management (PIM) for just-in-time elevation (Microsoft Entra ID > Privileged Identity Management), if available.
- Prefer group-based role assignments for easier management: create a group (e.g., "Subscription-Owners"), assign the role to the group, then add users to the group.


## Troubleshooting
- Can’t add/invite user: you need an Entra role like User Administrator or Global Administrator. Ask a tenant admin.
- Can’t assign role: you need Owner or User Access Administrator at that scope. Ask a Subscription Owner.
- User not found in role picker: confirm the user exists (or guest invite accepted). Refresh and try again.
- Permissions not applying: wait a few minutes; RBAC can take time to propagate.


## Escalation paths if no admin is available
- Ask the client to identify the Azure subscription “Account Owner” or Billing Admin; they can find or appoint a Subscription Owner.
- Check if the previous vendor will add you temporarily so you can take over.
- If the client has CSP/Partner-of-Record, contact the CSP to add you or transfer ownership.
- As a last resort, the client can open an Azure support ticket from their billing portal to recover access to the subscription/tenant.
