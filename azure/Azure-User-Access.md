# Azure: Read-only Access and Adding Users

This short guide shows how to (1) make a user read-only and (2) add a new user in Azure using the Azure Portal.


## Prerequisites
- You must have sufficient permissions (e.g., Owner or User Access Administrator at the target scope).
- Know the scope you want to grant access to: Subscription, Resource Group, or specific Resource.


## 1) Make an existing user read-only
Read-only access is provided by the built-in role "Reader". Assign it at the appropriate scope.

- Choose the scope:
  - Subscription: Home > Subscriptions > select your subscription
  - Resource Group: Home > Resource groups > select your RG
  - Resource: Open the specific resource (e.g., App Service, Storage Account)
- Open Access control (IAM) in the left menu.
- Click Add > Add role assignment.
- Role tab: select "Reader".
- Members tab: click Select members, find the user (by name/email), click Select.
- Review + assign.

Notes:
- Reader allows viewing resources and settings but not changing them.
- If the user has other roles at the same or higher scope, those may grant more permissions. Remove any broader roles if strict read-only is required.


## 2) Add a new user (Microsoft Entra ID)
First add the user to your tenant, then grant them access (e.g., Reader) to the desired scope.

- Go to Home > Microsoft Entra ID (Azure AD) > Users.
- Click New user > Create new user (or Invite external user for guests).
- Fill in required details (Name, User principal name). For guests, provide their email.
- Create the user.
- Grant access to Azure resources:
  - Navigate to the target scope (Subscription / Resource Group / Resource).
  - Open Access control (IAM) > Add > Add role assignment.
  - Choose a role (e.g., Reader for read-only).
  - Select the newly created user > Review + assign.


## Tips
- Scope matters: assigning Reader at Subscription cascades to all resource groups/resources within it.
- Least privilege: prefer the narrowest scope that meets the need.
- Conflicting access: if the user still has write permissions, check for other role assignments or group-based access.


## Troubleshooting
- User not found when assigning role: ensure the user is created in Entra ID or invited as a guest, and the invitation is accepted (for B2B guests).
- No Add role assignment button: you may lack permissions at that scope. Ask a Subscription Owner or User Access Administrator.
- Changes not reflected: wait a few minutes and refresh; RBAC propagation can take time.
