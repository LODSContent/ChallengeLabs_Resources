# Updating Lab Profiles to Remove Dependencies on CSS Cloud Slice Application

## Introduction

This training manual provides a step-by-step guide to updating a lab profile in Skillable Studio to eliminate dependencies on the CSS cloud slice application. This is necessary because the platform team will soon modify the application to rotate secrets on the "cloud-slice" app that is used for scripting. Currently, some Challenge Labs authenticate through the Cloud Slice app to run scripts against tenants, which may break in the future. By following this process, we disconnect that dependency and use per-tenant AppID/AppSecret for authentication.

Labs fall into two main types:
- **Prerequisite-based** — Student copies/pastes TenantName, Username, Password, ScriptingAppId, ScriptingAppSecret from a prerequisite setup lab that they run before starting a series.
- **Tenant pool-based** — Credentials pulled automatically from pool; Lifecycle Actions (LCAs) handle tenant cleanup/preparation (e.g., remove old resources, create TAP user).

This accompanying documentation contains copy/paste elements (updated auth blocks, LCA scripts, markdown sections):  
[Elements](https://github.com/LODSContent/ChallengeLabs_Resources/blob/master/docs/ScriptingAppUpdate-Elements.md)

## Step 1: Review Lab Profile Settings

1. Open the lab profile.
2. Navigate to the profile settings and inspect the components:
   - Check the network and attached virtual machines.
   - Note VM versions (e.g., older Windows Server). Plan updates to Server 2025 gold copies if applicable.
3. Evaluate VM replacement:
   - Single jump-box VM → replace with latest Windows 11 gold copy.
   - Multiple critical VMs → note for future update.
4. Check the Media Tab:
   - Review attached media (e.g., ISOs).
   - Scan instructions for dependencies.
   - Remove if unused.

## Step 2: Check for Tenant Pool (Lifecycle Tab)

1. Go to Lifecycle tab.
2. Look for tenant-related LCAs (e.g., "Tenant-Pool Staging", "Tenant Post Clean Up").
   - If present → tenant-pool lab.
   - If absent → prerequisite lab.
3. For tenant-pool labs: Staging LCA cleans/prepares tenant (removes resources, creates TAP). Cleanup LCA tears down (no TAP recreation).
4. For prerequisite based labs, there is a "Configure Tenant" activity that the student must click on after they have entered their saved Tenant details.

## Step 3: Modify Cloud Tab Configurations

1. On the Cloud tab:
2. Identify the subscription pool.
3. Determine lab type:
   - **Tenant pool with VMs** — Retain the subscription, but convert to a CSR subscription (bug: no cloud subscription → LCAs can't create variables if VMs attached; this bug has been reported).
   - **Tenant pool without VMs**: Safely remove subscription pool.
4. For removable cases:
   - Confirm instructions don't rely on subscription (e.g., no resource creation in subscription like Storage accounts or VMs).
   - Review for subscription vs. tenant logins.
   - Rare cases: Preserve if students act in both subscription and tenant.
5. Remove subscription pool:
   - Delete bottom-up to avoid residuals.
   - Set to "none" and save.
   - On error: Cancel, re-edit, verify removal, save again ("bump save"). 

## Step 4: Update Lifecycle Actions (Tenant Pool Labs Only)

1. In Lifecycle tab, replace staging and cleanup scripts with updated versions (from "Elements" link above).
2. For each LCA:
   - Set action to **Execute as custom script**.
   - Target: PowerShell 7.3.4 + Microsoft.Graph 2.25.0 (mismatch causes failures; avoid 2.26.0 or higher if incompatible).
3. Save changes.
4. Note: LCAs run in background; staging creates TAP/user vars; cleanup tears down.

## Step 5: Update Lab Variables

1. Add StagingComplete:
   - Name: StagingComplete (capital S/C).
   - Value: No (uppercase N).
   - Hides credentials until script/LCA completes.
2. Add/set Debug to True (enables notifications for LCA progress, cleanup details; turn off for production).

## Step 6: Update Lab Activities / Scoring Scripts

For each activity/script:
1. If only text-box/string verification → no changes.
2. If uses MgGraph (e.g., Get-MgUser):
   - Set target to Custom, PowerShell 7.3.4, Microsoft.Graph 2.25.0.
   - Replace auth block:
     - MgGraph-only (most cases; from documentation).
     - Combo Az + MgGraph if Connect-AzAccount used.
   - For beta commands: Load specific modules (e.g., Microsoft.Graph.Beta.DeviceManagement); test compatibility.
3. Inspect for stray Az commands; adjust block.
4. Disable unused/outdated activities if found.
5. Save.

## Step 7: Update Markdown Instructions

1. Update "Provide Your Saved Credentials" (prerequisite labs) using the block provided in the "Elements" link above:
   - Fields: TenantName, Password, ScriptingAppId, ScriptingAppSecret.
2. Set **Override Start Page** (profile settings):
   - Paste appropriate portal (e.g., https://admin.microsoft.com) for first login.
3. Handle instant launch (no VM/cloud delay, especially tenant-pool):
   - Use conditional sections on StagingComplete.
   - Initial: Show "Please wait while your tenant is being prepared" (LCA running).
   - After Yes: Reveal username/password.
   - Replace immediate logins to avoid blank placeholders.
4. Update other logins (e.g., entra.microsoft.com, endpoint.microsoft.com) as needed.
5. When "Configure Tenant" pressed (prereq) or lab launches (pool): Script/LCA runs, sets vars, updates StagingComplete to Yes.

## Step 8: Test the Lab

1. Launch lab.
2. **Prerequisite**: Provide test creds (TenantName, AppId, AppSecret, Username, Password).
   **Tenant pool**: Auto-pulls; wait for LCA (minutes; debug shows notifications/progress).
3. Verify:
   - Login works; credentials appear after staging.
   - Configuration/LCA runs without Cloud Slice.
   - Auth uses AppId/Secret.
   - Spot-check key activities (e.g., create user, verify scoring pass/fail).
   - Check debug output for cleanup/TAP success.
4. Initial: Basic tenant OK; end-to-end: Full M365 required.
5. Turn Debug to False for final version.
6. Recommend partial review (login + 1-2 validations) before handing over for a full tech review.

This completes the update. Adapt for lab type; test thoroughly for LCA/module compatibility.
