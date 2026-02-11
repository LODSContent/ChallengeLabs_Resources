# Dynamic VM Sizer – Training Guide

This guide explains how to implement the **Dynamic VM Sizer** PowerShell script as a Lifecycle Action (LCA) in Skillable Studio lab profiles. The script addresses ongoing issues with static VM size specifications in Azure labs, where sizes are frequently retired, restricted, or unavailable due to demand — especially in **Cloud Slice Subscription (CSS)** environments.

By running this script at lab startup (pre-build), we dynamically select the lowest-cost, policy-compliant VM size that meets minimum requirements and set it into a lab variable (`@lab.Variable(VMSize1)`). Lab instructions, resource templates, and activities then reference this variable instead of hard-coded sizes.

> **Goal**: Reduce lab maintenance effort and improve deployment reliability across regions and subscription types (CSS and eventually CSR).

## Why We Need Dynamic VM Sizing

- Microsoft regularly decommissions older VM SKUs (e.g., certain B-series, A-series).
- High-demand sizes become unavailable in some regions/subscriptions (especially CSS).
- Static sizes in instructions or ARM templates cause frequent lab breaks.
- The script finds the **cheapest available size** that satisfies:
  - Minimum vCPU and RAM (from `VMTargetSpec1`)
  - Maximum hourly price
  - Generation requirement (Gen1 or Gen2)
  - Allowed SKUs from Access Control Policy (ACP)
  - x64 architecture, no specialized hardware (GPU, HPC, etc.)

## Prerequisites & Core Concepts

Before modifying a lab, verify:

1. **Subscription Type** (Cloud tab)
   - **CSS**: Requires matching ACPs at **subscription** and **resource group** levels.
   - **CSR**: ACP only at resource group level.

2. **Resource Group Naming**
   - Standardize to `RG1` (or `RG1` + instance ID suffix for CSR compatibility).
   - Update Cloud tab → Resource Group Name & Replacement Token.

3. **ACP (Access Control Policy)**
   - Must contain a broad list of allowed VM SKUs (~80–85 sizes).
   - Reference: [Azure Policy Reference – Microsoft.Compute/virtualMachines section](https://github.com/LODSContent/ChallengeLabs_Resources/blob/master/ACPs/Azure%20Policy%20Reference.md)
   - Use latest version (e.g., `Azure Lockdown Storage Networking VM v4` or newer).
   - Location should use `[resourceGroup().location]`, not hard-coded regions.

4. **VM Deployment Locations**
   - Resource templates → Use parameter with default `[resourceGroup().location]`.
   - Instructions → Use `@lab.CloudResourceGroup(RG1).Location`.

## Step-by-Step Implementation

### Step 1: Update or Create Appropriate ACP

1. Search for existing ACPs matching your current one (e.g., `Azure Lockdown ... VM v*`).
2. Open the latest version or **Save As** → next version number.
3. In the `Microsoft.Compute/virtualMachines/sku.name` condition:
   - Replace the `in` array with the full list from the Azure Policy Reference (~83 sizes).
4. Standardize resource group checks to allow `RG1` and `RG1<instanceID>`.
5. Ensure location uses resource group location variable.
6. Save and note the new ACP name/version.

### Step 2: Attach Updated ACP to Lab Profile

- Cloud tab:
  - **Subscription ACP** (CSS only): Attach updated version.
  - **Resource Group ACP**: Attach same updated version.
- Save profile.

> **Note**: Attaching a new ACP to a production lab invalidates prior security review → request new review.

### Step 3: Add Dynamic VM Sizer Lifecycle Action

1. Edit lab profile → **Lifecycle Actions** tab.
2. **Add Lifecycle Action** with the following configuration:

| Setting          | Value                          | Notes |
|------------------|--------------------------------|-------|
| **LCA Name**     | Dynamic VM Sizer               | - |
| **Action**       | Execute Script in Cloud Platform | - |
| **Event**        | Pre-Build                      | Runs before ACP enforcement and resource template deployment |
| **Blocking**     | Yes                            | Subsequent actions wait for completion |
| **Delay**        | 0                              | No initial delay |
| **Timeout**      | 10 minutes                     | Default |
| **Repeat**       | No                             | - |
| **Retries**      | 0                              | - |
| **Error Action** | Log                            | - |
| **Enabled**      | Yes                            | - |

3. **Configuration**:
   - **Language**: PowerShell
   - **Version**: PS 7.4.0 | Az 11.1.0 (RC)

4. **Script Body**: Copy the full script content from [DynamicVMSizer-Launcher.ps1](https://github.com/LODSContent/ChallengeLabs_Resources/blob/master/LCAs/DynamicVMSizer-Launcher.ps1) and paste it directly into the LCA script body. This launcher script downloads and executes the full VM sizer logic from GitHub.
   - Ensure parameters match your ACP allowed list (especially `allowedSizes` array).
   - Set `Debug` variable to `true` during testing.
5. Save.

### Step 4: Configure Lab Variables

Add or verify these variables (Lab Profile → Variables tab). The script populates `@lab.Variable(VMSize1)` automatically.

| Variable Name     | Type    | Value Example                  | Purpose |
|-------------------|---------|--------------------------------|---------|
| `VMTargetSpec1`   | String  | `c2r4g2p0.20`                  | Minimum specs: 2 vCPU, 4 GB RAM, Gen2, max $0.20/hr (created by lab developer) |
| `@lab.Variable(VMSize1)` | String | (Populated by script)          | The dynamically selected VM size |
| `Debug`           | Boolean | `true` (testing) / `false` (prod) | Enables debug popup with selection details |

**TargetSpec breakdown** (format: `c<minCPU>r<minRAM>g<gen>p<maxPrice>`):
- `c2`  → minimum **2 vCPUs**
- `r4`  → minimum **4 GB** RAM
- `g2`  → requires **Generation 2** VM (preferred for Server 2022/2025, modern Ubuntu); use `g1` for very old OS
- `p0.20` → maximum **$0.20** / hr

### Step 5: Update Lab Instructions (Markdown)

Search & replace:

- Hard-coded VM sizes → `@lab.Variable(VMSize1)` (use **Copy** ++)
- Hard-coded regions → `@lab.CloudResourceGroup(RG1).Location`
- Hard-coded resource groups → `@lab.CloudResourceGroup(RG1).Name`
- Update OS to latest supported version when possible (Server 2025 / latest Ubuntu).

Example before/after:

```markdown
Before:
Create a Windows Server 2019 VM named VM1 in East US 2 using size Standard_B1ms.

After:
Create a Windows Server 2025 VM named VM1 in `@lab.CloudResourceGroup(RG1).Location` using size `@lab.Variable(VMSize1)`++.
```

### Step 6: Update Resource Templates (if present)

For each ARM template deploying VMs:

1. **Remove** `allowedValues` from `vmSize` parameter (avoid maintaining third list).
2. Set reasonable default if desired (fallback).
3. Ensure `location` parameter defaults to `[resourceGroup().location]`.
4. If VM size was hard-coded or used old variable → change to parameter `vmSize`.
5. In lab profile → **Edit Parameters** (under resource template):
   - Set `vmSize` value to `@lab.Variable(VMSize1)`

**Lab Variable for RT Parameters**: `@lab.Variable(VMSize1)` (created and populated by the VM Sizer script).

### Step 7: Update Lab Activities / Validation Scripts

- Replace hard-coded sizes, regions, RG names with tokens/properties.
- Remove or relax size checks (since size is now dynamic).
- Example: Instead of checking exact size, verify VM is running and correct OS.

### Step 8: Test & Debug

1. Set `Debug` = `true`.
2. Launch lab.
3. Watch for debug popup/notification → shows:
   - Target spec parsed
   - Number of candidates
   - Policy-allowed sizes considered
   - Final selected size & price
4. Deploy VM manually or via template.
5. Confirm selected size appears correctly and deployment succeeds.
6. Set `Debug` = `false` before publishing.

## Common Troubleshooting

- **No candidates found** → Increase max price (e.g., `$0.30`), lower min specs, check ACP list includes chosen size.
- **Size chosen but deployment fails** → Ensure ACP includes that SKU (case-sensitive).
- **Old OS requires Gen1** → Set `g1` in target spec.
- **Region issues** → Prefer regions with better availability (e.g., West US 2 over East US).

## Sample Labs

- **With modified ACP**: WSHA.1-006t: Can You Deploy and Manage Windows Server on Microsoft Azure Virtual Machines? [Advanced] (MJM-Testing) | Skillable Studio
- **With modified ACP and RT**: WSHA.1-005t: Manage Windows Server on an Azure Virtual Machine by using Azure Policy Guest Configuration [Guided] (MJM-Testing) | Skillable Studio

## References

- [Skillable Lifecycle Actions Documentation](https://docs.skillable.com/docs/life-cycle-actions-5)
- [Skillable Variables & Replacement Tokens](https://docs.skillable.com/docs/variables-1)
- [ACP Best Practices](https://docs.skillable.com/docs/acp-best-practices)
- [Azure Policy Reference (VM SKUs)](https://github.com/LODSContent/ChallengeLabs_Resources/blob/master/ACPs/Azure%20Policy%20Reference.md)
- [Dynamic VM Sizer Launcher Script](https://github.com/LODSContent/ChallengeLabs_Resources/blob/master/LCAs/DynamicVMSizer-Launcher.ps1)
- Internal GitHub location for launcher script & full sizer logic

This process significantly reduces future VM-related breakages. Apply it proactively to labs showing size-related failures. For questions, reach out to the team maintaining the Dynamic VM Sizer script.
