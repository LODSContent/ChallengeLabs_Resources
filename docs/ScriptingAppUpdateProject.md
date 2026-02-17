# Updating Lab Profiles to Remove Dependencies on CSS Cloud Slice Application

## Introduction

This training manual provides a step-by-step guide to updating a lab profile in Skillable Studio to eliminate dependencies on the CSS cloud slice application. This is necessary because the platform team will soon modify the application to rotate credentials or secrets. Currently, some prerequisite and tenant pool-based labs authenticate through the Cloud Slice app to run scripts against tenants, which may break in the future. By following this process, we disconnect that dependency.

We will use an example lab based on a student prerequisite (MD102.1-003) to demonstrate the updates. The process involves reviewing profile settings, modifying cloud configurations, updating lab activities and scripts, and adjusting markdown instructions.

## Step 1: Review Lab Profile Settings

1. Open the lab profile (e.g., MD102.1-003).
2. Navigate to the profile settings and inspect the components:
   - Check the network and attached virtual machines.
   - Note the versions of virtual machines (e.g., older Windows Server versions). If applicable, plan to update to Server 2025 gold copies in the future.
3. Evaluate if the lab is a good candidate for replacing virtual machines:
   - If only one VM (e.g., Windows 10 client as a jump box), replace it with the latest Windows 11 jump box based on gold copies.
   - If multiple critical VMs are present, defer updates for now.

## Step 2: Check Media Tab

1. Review attached media (e.g., ISO images).
2. Scan the lab instructions to ensure no dependencies on these ISOs.
3. If not required, remove the ISOs.

## Step 3: Modify Cloud Tab Configurations

1. Focus on the cloud tab, which is critical for this update.
2. Identify if it's using a CSS subscription pool.
3. Determine the lab type:
   - If based on a tenant pool (with cloud credential pool under advanced settings and lifecycle actions for cleanup), retain a CSS or CSR subscription due to a current bug where variables are not created in LCAs without a cloud subscription if VMs are attached. (Bug reported.)
   - If based on student prerequisite (no tenant pool, only LCA for downloading lab files), safely remove the subscription pool.
4. For prerequisite-based labs:
   - Confirm no instructions rely on subscription credentials (e.g., creating resources like resource groups, storage accounts, or VMs in the subscription).
   - Peruse instructions: Look for references to logging into the subscription vs. the tenant.
5. Remove the subscription pool:
   - Delete components from the bottom up to avoid residual traces.
   - Set to "none" and save.
   - If an application error occurs, it still saves; cancel, re-edit, and verify removal.
   - Save again to confirm.

Note: Rare cases may require preserving the subscription if students perform actions in both subscription and tenant.

## Step 4: Update Lab Variables

1. Add a new variable for staging completion:
   - Name: StagingComplete (capital S and C).
   - Value: No (uppercase N).
   - This hides credentials until the configuration script completes.

Leave existing variables like Debug (set to true).

## Step 5: Update Lab Activities

1. Locate the non-scored "Configure Tenant" activity at the bottom.
2. Replace the script with the updated version (provided in documentation: header "Tenant Pool Staging" for Configure-Tenant Activity).
3. In configuration:
   - Set target to Custom.
   - PowerShell: 7.3.4.
   - Microsoft.Graph: 2.2.5 (not 2.2.6, as it requires higher PowerShell; custom container limits to 7.3.4).
   - If AZ commands are used (e.g., in tenant staging), add Az: 11.1.0.
   - Cloud subscriptions inherently include Az; custom targets may require explicit addition.

Note: If scripts only use MgGraph commands for validation, omit Az module.

## Step 6: Update Scoring Scripts

For each scoring script in lab activities:

1. Change target to Custom, PowerShell 7.3.4, Microsoft.Graph 2.2.5.
2. Inspect commands:
   - If only Connect-MgGraph and Get-Mg* commands, use MgGraph-only authentication block (provided in documentation).
   - If AZ commands (e.g., Connect-AzAccount), use combined MgGraph + AZ authentication block.
3. Replace authentication block:
   - Sets credentials using ScriptingAppId, ScriptingAppSecret, and TenantName from student input.
4. For beta commands (e.g., Get-MgBetaDeviceManagement):
   - Ensure compatibility with Microsoft.Graph 2.2.5.
   - Load specific modules like Microsoft.Graph.Beta.DeviceManagement, Microsoft.Graph.Groups if needed.
5. Eyeball scripts for stray AZ commands; remove or adjust as necessary.
6. Save changes.

Example updates for requirements (order may vary):
- Requirement 6: MgGraph only.
- Others: Similar checks and replacements.

Test module compatibility during lab testing.

## Step 7: Update Markdown Instructions

1. Update "Provide Your Saved Credentials" section:
   - Add fields for TenantName, Password, ScriptingAppId, ScriptingAppSecret (students copy from prerequisite lab).
   - Use updated block (provided in documentation).
2. Update login sections to handle staging:
   - Use conditional sections based on StagingComplete.
   - Hide credentials until "Yes"; show "Please wait while your tenant is being prepared."
   - Replace placeholders with variables.
   - Examples:
     - Sign in to endpoint.microsoft.com (first occurrence).
     - Sign in to entra.microsoft.com (subsequent).
3. Ensure no immediate logins show blank credentials to avoid confusion.
4. After "Configure Tenant" button, script runs, sets variables (including StagingComplete to Yes), and reveals credentials.

## Step 8: Test the Lab

1. Launch the lab.
2. Use test credentials (TenantName, AppId, AppSecret, Username, Password).
   - Initial testing: Basic tenant sufficient.
   - End-to-end: Full M365 subscription required.
3. Verify:
   - Configuration script runs without Cloud Slice dependency.
   - Authentication uses new AppId/Secret.
   - All activities score correctly.
   - No errors from module versions.

This completes the update process. Repeat for other labs, adapting based on tenant pool vs. prerequisite types.
