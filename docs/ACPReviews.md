# Pre-Security Review Process for Azure Lab Profiles

This manual serves as a companion to the video on reviewing and updating Access Control Policies (ACPs) for lab profiles in the Azure training environment. It outlines the step-by-step process to ensure lab profiles align with security standards before submission to the security team. This helps prevent rejections and ensures compliance with cost controls and abuse prevention measures.

For additional reference:
- [ACP Best Practices](https://docs.skillable.com/docs/acp-best-practices)
- [Azure Access Control Policy Creation](https://docs.skillable.com/docs/azure-access-control-policy-creation)
- [Replacement Tokens](https://docs.skillable.com/docs/replacement-tokens)
- [Lab Activities](https://docs.skillable.com/docs/activities)
- [Azure Policy Reference](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/ACPs/Azure Policy Reference.md)

## Introduction

The process involves reviewing a lab profile prior to security review. This includes examining the ACPs, Resource Templates (RTs), lab instructions, and lab activities to ensure they meet established standards. The goal is to align everything with security policies, standardize naming conventions, and provide flexibility where needed (e.g., VM sizes).

Key components:
- **Subscription Mode**: Check if the lab uses Cloud Slice Subscription (CSS) or Cloud Slice Resource Group (CSR).
- **ACPs**: Restrict resources to prevent abuse and control costs.
- **RTs**: Pre-deployed resources (covered in a separate video and document).
- **Lab Instructions**: Markdown-based, using replacement tokens for dynamic values like resource group names, regions, and lab instance IDs.
- **Lab Activities**: PowerShell scripts for validation, also using tokens where applicable.

In this manual, the lab is assumed to be in CSR mode with no RTs, focusing primarily on the ACP.

## Step 1: Access the Lab Profile

1. Open the lab profile in edit mode.
2. Navigate to the **Cloud** tab.
3. Identify the subscription mode:
   - **CSR**: ACP applied only at the resource group level.
   - **CSS**: ACP applied at both subscription and resource group levels (typically the same ACP).
4. Note any attached ACPs and RTs and the resources they cover. For example: Cosmos DB, Key Vault, Storage, Network, SQL, and VMs (e.g., version 2).

## Step 2: Initial ACP Review

Open the ACP in a new tab and perform a visual inspection:

- **VM Sizes (SKUs)**: Check the allowed VM sizes (e.g., `Standard_B2ms`). Avoid limiting to one size due to regional availability issues. Use a broad list of ~80 SKUs from the [Azure Policy Reference](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/ACPs/Azure Policy Reference.md) for flexibility.
- **Resource Names**: Ensure restrictions like VM names (e.g., `web-vm`) are flexible but limited to prevent abuse.
- **Resource Group ID**: Standardize to `RG1` (with and without lab instance ID appended for CSR/CSS compatibility).
- **Location Restrictions**: Use `resourceGroup().location` and `location "notEquals" global` to avoid hardcoding regions.
- **SQL Servers**: Restrict names (e.g., `sql-` concatenated with lab instance ID), IDs to `RG1`, and locations.
- **SQL Databases**: Add name restrictions (e.g., `db` concatenated with lab instance ID, plus `master` for built-in database). Include SKU, tier, capacity, and location restrictions.
- **Document DB (Cosmos DB)**: Restrict SKUs, names (e.g., `cosmos`), throughput (e.g., 4000), IDs to `RG1`, and locations (add `!= global` if missing).
- **Other Resources**: Review Key Vaults, Compute Disks, VM Extensions, Insights, Storage Accounts, and Networking for similar standards.

Use the [Azure Policy Reference](https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/ACPs/Azure Policy Reference.md) as the "gold standard" for policy blocks.

## Step 3: Create a New ACP Version

If the lab is already in production, save the ACP as a new version to avoid invalidating the current one:

1. Click **Save As** and name it with the next version (e.g., `v3` or `v4`).
2. Edit the new ACP.

### Update VM SKUs

- Navigate to the `Microsoft.Compute/virtualMachines` resource type in the Policy Reference document.
- Replace the SKU list with the full list from the reference (e.g., B-series v2, D-series v5/v6, E, F, L series).
- Example JSON block (ensure proper brackets and commas):

```json
{
  "field": "Microsoft.Compute/virtualMachines/sku.name",
  "in": [
    "Standard_B2as_v2",
    "Standard_B2ats_v2",
    "Standard_B2ls_v2",
    "Standard_B2ms",
    // ... (full list of ~80 SKUs)
  ]
}
```

- Update VM name restrictions if needed (e.g., add alternatives like `vm1`, `vm2` but keep limited).

### Standardize Resource Group IDs

- For all resources (e.g., VMs, SQL Servers, Databases, Document DB), replace IDs with `RG1` variants for CSS/CSR compatibility.
- Example:

```json
{
	"anyOf": [
		{
			"field": "id",
			"contains": "/resourceGroups/RG1/"
		},
		{
			"field": "id",
			"contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
		}
	]
},
```

### Add Missing Restrictions

- **SQL Databases**: Add name restriction including `master`:

```json
{
	"field": "name",
	"in": [
		"SalesDB",
		"master"
	]
},
```

- Add location restriction if missing:

```json
{
	"field": "location",
	"In": [
		"[resourceGroup().location]"
	]
},
{
	"field": "location",
	"notEquals": "global"
}
```

Ensure JSON syntax is valid (no red squiggles in editor).

## Step 4: Update Lab Instructions

1. Open the lab instructions in edit mode.
2. Update hardcoded names with replacement tokens:
   - Resource group: `@lab.CloudResourceGroup(RG1).Name` or similar.
   - Locations: Replace hardcoded values (e.g., `eastus`) with `@lab.CloudResourceGroup(RG1).Location`.
3. Update VM sizes: Change to a supported SKU (e.g., `Standard_B2as_v2` instead of `Standard_B2ms` due to deprecation).
4. Search and replace occurrences (e.g., find `eastus` or old IDs).
5. For database names: Ensure concatenation like `db@lab.LabInstanceId` (no dash unless intended).

## Step 5: Update Lab Activities (Validation Scripts)

1. Open **Lab Activities**.
2. In each PowerShell script:
   - Replace hardcoded resource groups (e.g., `corp-data`) with tokens: `$resourceGroupName = "@lab.CloudResourceGroup(RG1).Name"`.
   - Update locations if hardcoded: Use `@lab.CloudResourceGroup.Location`.
3. Manually check and replace in each script (no global replace available).

## Step 6: Attach the New ACP and Test

1. Edit the lab profile > **Cloud** tab.
2. Attach the new ACP version to the resource group (and subscription if CSS).
3. Save changes.
4. Test launch the lab:
   - If RTs are present, verify deployment.
   - Otherwise, simulate student steps to ensure all actions pass ACP restrictions.
5. If issues arise, iterate on updates.

## Conclusion

This process ensures the lab profile is aligned with standards, reducing security review rejections. Standardizing on `RG1`, using tokens for locations, and providing VM flexibility improves maintainability. Future enhancements may include standardized database names and automated VM sizer scripts for availability checks.

If RTs are involved, refer to a separate process for their review.
