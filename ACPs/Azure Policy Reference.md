# Skillable Approved - Azure Policy Reference

## Table of Contents

- [Resource Group id Examples](#resource-group-id-examples)
- [Location (region) examples](#location-region-examples)
- [Microsoft.App/containerApps](#microsoftappcontainerapps)
- [Microsoft.CognitiveServices](#microsoftcognitiveservices)
- [Microsoft.Automation](#microsoftautomation)
- [Microsoft.Compute/virtualMachines](#microsoftcomputevirtualmachines)
- [Microsoft.Compute/virtualMachineScaleSets](#microsoftcomputevirtualmachinescalesets)
- [Microsoft.ContainerInstance/containerGroups](#microsoftcontainerinstancecontainergroups)
- [Microsoft.ContainerRegistry](#microsoftcontainerregistry)
- [Microsoft.DataFactory](#microsoftdatafactory)
- [Microsoft.DBforMySQL](#microsoftdbformysql)
- [Microsoft.DocumentDB](#microsoftdocumentdb)
- [Microsoft.EventGrid/topics](#microsofteventgridtopics)
- [Microsoft.EventGrid/systemTopics](#microsofteventgridsystemtopics)
- [Microsoft.EventHub](#microsofteventhub)
- [Microsoft.Network](#microsoftnetwork)
- [Microsoft.OperationalInsights](#microsoftoperationalinsights) (Log Analytics Workspace - Azure Monitor Workspace)
- [Microsoft.RecoveryServices](#microsoftrecoveryservices)
- [Microsoft.Search](#microsoftsearch)
- [Microsoft.Sql/servers](#microsoftsqlservers)
- [Microsoft.SqlVirtualMachines](#microsoftsqlvirtualmachines)
- [Microsoft.Synapse](#microsoftsynapse)
- [Microsoft.Web - Function App](#microsoftweb---function-app)
- [Microsoft.Web/serverfarms](#microsoftwebserverfarms)
- [Microsoft.Web/sites](#microsoftwebsites)
---
<br><br>

## High-Threat Resources

> The following resources are considered "High-Threat" by the security team and are discouraged for use by Challenge Labs.
<br>

| Resource Type                                      | Severity    | Status                  | Notes                          |
|----------------------------------------------------|-------------|-------------------------|--------------------------------|
| Microsoft.AzureActiveDirectory/ciamDirectories     | Blocked     | Restricted              | All Labs, Threat to platform availability - id_202 |
| Microsoft.ContainerRegistry/registries             | Very High   | Restricted              | Unmitigated                    |
| Microsoft.Databricks                               | Very High   | Under Review            |                                |
| Microsoft.Databricks/workspaces                    | Very High   | Under Review            |                                |
| Microsoft.Fabric/capacities                        | Very High   | Restricted              | (Crypto/Compute)               |
| Microsoft.MachineLearningServices/workspaces       | Very High   | Restricted              | (Crypto/Compute)               |
| Microsoft.Synapse/workspaces                       | Very High   | Restricted              | Unmitigated                    |

---
[Back to TOC:](#table-of-contents)
<br><br>

## Resource Group id Examples

> **Purpose**: These are policy fragments used to restrict resource placement by Resource Group ID. They support dynamic naming (using `corp-data` + tags `LODManaged` and `LabInstance`), static names (`rg1`), or multiple allowed patterns (RG1 with or without tags). Use in combination with other policies.

```json
{
    "field": "id",
    "contains": "[concat('/resourceGroups/corp-data',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
}
```

> *Note*: `//using dynamically generated RG name`

```json
{
    "field": "id",
    "contains": "/resourceGroups/rg1/"
}
```

> *Note*: `// using a static RG name`

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
}
```

> *Note*: `// Allowing CSS and CSR variations in the same ACP. This should be used whenever possible.`
---
[Back to TOC:](#table-of-contents)
<br><br>

## Location (region) examples

> **Purpose**: Ensures resources are deployed in the same region as their Resource Group (`[resourceGroup().location]`) and never in the invalid `global` region. Optionally allows `eastus2` as an alternate approved region to prevent deployment drift and enforce regional compliance.
>
> In general, only the `[resourceGroup().location]` should be used for the resource's region. The only time an alternate region should be used is if a secondary region is used as part of the lab itself.

```json```

```json
{
    "field": "location",
    "notEquals": "global"
}
```

> *Note*: `// location based upon the location of the current resource group`  
> *Note*: The location property is no longer required by Security and can be removed from ACPs. However, the "notEquals": "global" should still be added.
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.App/containerApps

> **Purpose**: Allows only approved Azure Container Apps and Managed Environments with strict naming (`ca{LabInstance}`, `env{LabInstance}`), placement in allowed Resource Groups, and same-region deployment. Supporting resources (Storage, Network) are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "contains": "Microsoft.App/containerApps"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('ca',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        },]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "contains": "Microsoft.App/managedEnvironments"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('env',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.CognitiveServices

> **Purpose**: Allows Azure OpenAI service (`OpenAI{LabInstance}`, kind `OpenAI`, SKU `S0`) in allowed RG and region. Model deployments are explicitly restricted by model name, SKU name, SKU capacity, and SKU tier using `allOf` in ALL mode — the narrowest allowable set of models and a capacity no higher than required for lab objectives. Supporting infrastructure (Storage, Network) is permitted.
>
> **Note**: ACPs that allow `Microsoft.CognitiveServices/accounts/deployments` **must** be implemented in ALL mode and **must** restrict `model.name`, `sku.name`, `sku.capacity`, and `sku.tier` using an `allOf` block. The model list should be as narrow as possible. CSR/CSS-R profiles must also implement an LCA that purges soft-deleted Cognitive Services resources.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.CognitiveServices/accounts"
                        },
                        {
                            "field": "kind",
                            "equals": "OpenAI"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('OpenAI',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "equals": "S0"
                        },

                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.CognitiveServices/accounts/deployments"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('gpt-4o-',resourcegroup().tags.LabInstance)]",
                                "[concat('gpt-35-turbo-',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        {
                            "field": "Microsoft.CognitiveServices/accounts/deployments/model.name",
                            "in": [
                                "gpt-4o",
                                "gpt-35-turbo"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/deployments/sku.name",
                            "in": [
                                "Standard",
                                "GlobalStandard"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/deployments/sku.tier",
                            "in": [
                                "Standard",
                                "Enterprise"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/deployments/sku.capacity",
                            "lessOrEquals": 10
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Automation

> **Purpose**: Allows Automation Accounts with names `autoacct` or `lab{LODManaged}{LabInstance}-autoacct`, Basic SKU, no capacity, in allowed RGs and region. Permits specific runbooks (`runbook1`, tutorial scripts) of types Python, PowerShell, GraphPowerShell.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Automation/automationAccounts"
                        },
                        {
                            "field": "name",
                            "in": [
                                "autoacct",
                                "[concat('lab',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'-autoacct')]"
                            ]
                        },
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
                        {
                            "field": "Microsoft.Automation/automationAccounts/sku.name",
                            "equals": "Basic"
                        },
                        {
                            "field": "Microsoft.Automation/automationAccounts/sku.capacity",
                            "exists": "false"
                        },

                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Automation/automationAccounts/Runbooks"
                        },
                        {
                            "field": "name",
                            "in": [
                                "runbook1",
                                "AzureAutomationTutorialWithIdentity",
                                "AzureAutomationTutorialWithIdentityGraphical"
                            ]
                        },
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
                        {
                            "field": "Microsoft.Automation/automationAccounts/runbooks/runbookType",
                            "in": [
                                "Python",
                                "PowerShell",
                                "GraphPowerShell"
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Compute/virtualMachines

> **Purpose**: Allows only approved VM SKUs (B-series, D-series, E-series, F-series, L-series) and names (`VM1`, `VM2`, `VM1-{LabInstance}`) in allowed RGs and same region. Supporting resources (Storage for boot diagnostics, Network) are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Compute/virtualMachines"
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachines/sku.name",
                            "in": [
                                "Standard_B2als_v2",
                                "Standard_B2as_v2",
                                "Standard_B2ats_v2",
                                "Standard_B2ls_v2",
                                "Standard_B2ps_v2",
                                "Standard_B2s_v2",
                                "Standard_B2ts_v2",
                                "Standard_B4als_v2",
                                "Standard_B4as_v2",
                                "Standard_B4ls_v2",
                                "Standard_B4ps_v2",
                                "Standard_B4s_v2",
                                "Standard_B8as_v2",
                                "Standard_B8ls_v2",
                                "Standard_B8ps_v2",
                                "Standard_B8s_v2",
                                "Standard_D2ads_v5",
                                "Standard_D2ads_v6",
                                "Standard_D2alds_v6",
                                "Standard_D2als_v6",
                                "Standard_D2as_v4",
                                "Standard_D2as_v5",
                                "Standard_D2as_v6",
                                "Standard_D2ds_v5",
                                "Standard_D2ds_v6",
                                "Standard_D2lds_v5",
                                "Standard_D2lds_v6",
                                "Standard_D2ls_v5",
                                "Standard_D2ls_v6",
                                "Standard_D2s_v3",
                                "Standard_D2s_v4",
                                "Standard_D2s_v5",
                                "Standard_D2s_v6",
                                "Standard_D4ads_v5",
                                "Standard_D4ads_v6",
                                "Standard_D4as_v5",
                                "Standard_D4as_v6",
                                "Standard_D4ds_v5",
                                "Standard_D4ds_v6",
                                "Standard_D4s_v5",
                                "Standard_D4s_v6",
                                "Standard_D8as_v5",
                                "Standard_D8as_v6",
                                "Standard_D8ds_v5",
                                "Standard_D8ds_v6",
                                "Standard_D8s_v5",
                                "Standard_D8s_v6",
                                "Standard_E2ads_v5",
                                "Standard_E2ads_v6",
                                "Standard_E2as_v5",
                                "Standard_E2as_v6",
                                "Standard_E2ds_v5",
                                "Standard_E2ds_v6",
                                "Standard_E2s_v5",
                                "Standard_E2s_v6",
                                "Standard_E4ads_v5",
                                "Standard_E4ads_v6",
                                "Standard_E4as_v5",
                                "Standard_E4as_v6",
                                "Standard_E4ds_v5",
                                "Standard_E4ds_v6",
                                "Standard_E4s_v5",
                                "Standard_E4s_v6",
                                "Standard_E8ads_v5",
                                "Standard_E8ads_v6",
                                "Standard_E8as_v5",
                                "Standard_E8as_v6",
                                "Standard_E8ds_v5",
                                "Standard_E8ds_v6",
                                "Standard_E8s_v5",
                                "Standard_E8s_v6",
                                "Standard_F2s_v2",
                                "Standard_F4s_v2",
                                "Standard_F8s_v2",
                                "Standard_L2s_v4",
                                "Standard_L2as_v4",
                                "Standard_L2aos_v4",
                                "Standard_L4s_v4",
                                "Standard_L4as_v4",
                                "Standard_L4aos_v4",
                                "Standard_L8s_v4",
                                "Standard_L8as_v4",
                                "Standard_L8aos_v4"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "VM1",
                                "VM2",
                                "[concat('VM1-',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Compute/virtualMachineScaleSets

> **Purpose**: Allows VMSS and member VMs with specific names, SKUs, scale limits (≤4), and supporting infrastructure (Network, Disks, Autoscale, Extensions, Storage).

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Compute/virtualMachines"
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachines/sku.name",
                            "in": [
                                "Standard_B2als_v2",
                                "Standard_B2as_v2",
                                "Standard_B2ats_v2",
                                "Standard_B2ls_v2",
                                "Standard_B2ps_v2",
                                "Standard_B2s_v2",
                                "Standard_B2ts_v2",
                                "Standard_B4als_v2",
                                "Standard_B4as_v2",
                                "Standard_B4ls_v2",
                                "Standard_B4ps_v2",
                                "Standard_B4s_v2",
                                "Standard_B8as_v2",
                                "Standard_B8ls_v2",
                                "Standard_B8ps_v2",
                                "Standard_B8s_v2",
                                "Standard_D2ads_v5",
                                "Standard_D2ads_v6",
                                "Standard_D2alds_v6",
                                "Standard_D2als_v6",
                                "Standard_D2as_v4",
                                "Standard_D2as_v5",
                                "Standard_D2as_v6",
                                "Standard_D2ds_v5",
                                "Standard_D2ds_v6",
                                "Standard_D2lds_v5",
                                "Standard_D2lds_v6",
                                "Standard_D2ls_v5",
                                "Standard_D2ls_v6",
                                "Standard_D2s_v3",
                                "Standard_D2s_v4",
                                "Standard_D2s_v5",
                                "Standard_D2s_v6",
                                "Standard_D4ads_v5",
                                "Standard_D4ads_v6",
                                "Standard_D4as_v5",
                                "Standard_D4as_v6",
                                "Standard_D4ds_v5",
                                "Standard_D4ds_v6",
                                "Standard_D4s_v5",
                                "Standard_D4s_v6",
                                "Standard_D8as_v5",
                                "Standard_D8as_v6",
                                "Standard_D8ds_v5",
                                "Standard_D8ds_v6",
                                "Standard_D8s_v5",
                                "Standard_D8s_v6",
                                "Standard_E2ads_v5",
                                "Standard_E2ads_v6",
                                "Standard_E2as_v5",
                                "Standard_E2as_v6",
                                "Standard_E2ds_v5",
                                "Standard_E2ds_v6",
                                "Standard_E2s_v5",
                                "Standard_E2s_v6",
                                "Standard_E4ads_v5",
                                "Standard_E4ads_v6",
                                "Standard_E4as_v5",
                                "Standard_E4as_v6",
                                "Standard_E4ds_v5",
                                "Standard_E4ds_v6",
                                "Standard_E4s_v5",
                                "Standard_E4s_v6",
                                "Standard_E8ads_v5",
                                "Standard_E8ads_v6",
                                "Standard_E8as_v5",
                                "Standard_E8as_v6",
                                "Standard_E8ds_v5",
                                "Standard_E8ds_v6",
                                "Standard_E8s_v5",
                                "Standard_E8s_v6",
                                "Standard_F2s_v2",
                                "Standard_F4s_v2",
                                "Standard_F8s_v2",
                                "Standard_L2s_v4",
                                "Standard_L2as_v4",
                                "Standard_L2aos_v4",
                                "Standard_L4s_v4",
                                "Standard_L4as_v4",
                                "Standard_L4aos_v4",
                                "Standard_L8s_v4",
                                "Standard_L8as_v4",
                                "Standard_L8aos_v4"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('vm',resourcegroup().tags.LabInstance,'jbox')]"
                            ]
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Compute/virtualMachines"
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachines/sku.name",
                            "in": [
                                "Standard_B2als_v2",
                                "Standard_B2as_v2",
                                "Standard_B2ats_v2",
                                "Standard_B2ls_v2",
                                "Standard_B2ps_v2",
                                "Standard_B2s_v2",
                                "Standard_B2ts_v2",
                                "Standard_B4als_v2",
                                "Standard_B4as_v2",
                                "Standard_B4ls_v2",
                                "Standard_B4ps_v2",
                                "Standard_B4s_v2",
                                "Standard_B8as_v2",
                                "Standard_B8ls_v2",
                                "Standard_B8ps_v2",
                                "Standard_B8s_v2",
                                "Standard_D2ads_v5",
                                "Standard_D2ads_v6",
                                "Standard_D2alds_v6",
                                "Standard_D2als_v6",
                                "Standard_D2as_v4",
                                "Standard_D2as_v5",
                                "Standard_D2as_v6",
                                "Standard_D2ds_v5",
                                "Standard_D2ds_v6",
                                "Standard_D2lds_v5",
                                "Standard_D2lds_v6",
                                "Standard_D2ls_v5",
                                "Standard_D2ls_v6",
                                "Standard_D2s_v3",
                                "Standard_D2s_v4",
                                "Standard_D2s_v5",
                                "Standard_D2s_v6",
                                "Standard_D4ads_v5",
                                "Standard_D4ads_v6",
                                "Standard_D4as_v5",
                                "Standard_D4as_v6",
                                "Standard_D4ds_v5",
                                "Standard_D4ds_v6",
                                "Standard_D4s_v5",
                                "Standard_D4s_v6",
                                "Standard_D8as_v5",
                                "Standard_D8as_v6",
                                "Standard_D8ds_v5",
                                "Standard_D8ds_v6",
                                "Standard_D8s_v5",
                                "Standard_D8s_v6",
                                "Standard_E2ads_v5",
                                "Standard_E2ads_v6",
                                "Standard_E2as_v5",
                                "Standard_E2as_v6",
                                "Standard_E2ds_v5",
                                "Standard_E2ds_v6",
                                "Standard_E2s_v5",
                                "Standard_E2s_v6",
                                "Standard_E4ads_v5",
                                "Standard_E4ads_v6",
                                "Standard_E4as_v5",
                                "Standard_E4as_v6",
                                "Standard_E4ds_v5",
                                "Standard_E4ds_v6",
                                "Standard_E4s_v5",
                                "Standard_E4s_v6",
                                "Standard_E8ads_v5",
                                "Standard_E8ads_v6",
                                "Standard_E8as_v5",
                                "Standard_E8as_v6",
                                "Standard_E8ds_v5",
                                "Standard_E8ds_v6",
                                "Standard_E8s_v5",
                                "Standard_E8s_v6",
                                "Standard_F2s_v2",
                                "Standard_F4s_v2",
                                "Standard_F8s_v2",
                                "Standard_L2s_v4",
                                "Standard_L2as_v4",
                                "Standard_L2aos_v4",
                                "Standard_L4s_v4",
                                "Standard_L4as_v4",
                                "Standard_L4aos_v4",
                                "Standard_L8s_v4",
                                "Standard_L8as_v4",
                                "Standard_L8aos_v4"
                            ]
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachines/virtualMachineScaleSet.id",
                            "contains": "[concat('/resourceGroups/corp-data',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/providers/Microsoft.Compute/virtualMachineScaleSets/vmfe',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "name",
                            "contains": "[concat('vmfe',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Compute/virtualMachineScaleSets"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('vmfe',resourcegroup().tags.LabInstance)]",
                                "[concat('vm',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        {
                            "field": "Microsoft.Compute/virtualMachineScaleSets/sku.name",
                            "in": [
                                "Standard_B2als_v2",
                                "Standard_B2as_v2",
                                "Standard_B2ats_v2",
                                "Standard_B2ls_v2",
                                "Standard_B2ps_v2",
                                "Standard_B2s_v2",
                                "Standard_B2ts_v2",
                                "Standard_B4als_v2",
                                "Standard_B4as_v2",
                                "Standard_B4ls_v2",
                                "Standard_B4ps_v2",
                                "Standard_B4s_v2",
                                "Standard_B8as_v2",
                                "Standard_B8ls_v2",
                                "Standard_B8ps_v2",
                                "Standard_B8s_v2",
                                "Standard_D2ads_v5",
                                "Standard_D2ads_v6",
                                "Standard_D2alds_v6",
                                "Standard_D2als_v6",
                                "Standard_D2as_v4",
                                "Standard_D2as_v5",
                                "Standard_D2as_v6",
                                "Standard_D2ds_v5",
                                "Standard_D2ds_v6",
                                "Standard_D2lds_v5",
                                "Standard_D2lds_v6",
                                "Standard_D2ls_v5",
                                "Standard_D2ls_v6",
                                "Standard_D2s_v3",
                                "Standard_D2s_v4",
                                "Standard_D2s_v5",
                                "Standard_D2s_v6",
                                "Standard_D4ads_v5",
                                "Standard_D4ads_v6",
                                "Standard_D4as_v5",
                                "Standard_D4as_v6",
                                "Standard_D4ds_v5",
                                "Standard_D4ds_v6",
                                "Standard_D4s_v5",
                                "Standard_D4s_v6",
                                "Standard_D8as_v5",
                                "Standard_D8as_v6",
                                "Standard_D8ds_v5",
                                "Standard_D8ds_v6",
                                "Standard_D8s_v5",
                                "Standard_D8s_v6",
                                "Standard_E2ads_v5",
                                "Standard_E2ads_v6",
                                "Standard_E2as_v5",
                                "Standard_E2as_v6",
                                "Standard_E2ds_v5",
                                "Standard_E2ds_v6",
                                "Standard_E2s_v5",
                                "Standard_E2s_v6",
                                "Standard_E4ads_v5",
                                "Standard_E4ads_v6",
                                "Standard_E4as_v5",
                                "Standard_E4as_v6",
                                "Standard_E4ds_v5",
                                "Standard_E4ds_v6",
                                "Standard_E4s_v5",
                                "Standard_E4s_v6",
                                "Standard_E8ads_v5",
                                "Standard_E8ads_v6",
                                "Standard_E8as_v5",
                                "Standard_E8as_v6",
                                "Standard_E8ds_v5",
                                "Standard_E8ds_v6",
                                "Standard_E8s_v5",
                                "Standard_E8s_v6",
                                "Standard_F2s_v2",
                                "Standard_F4s_v2",
                                "Standard_F8s_v2",
                                "Standard_L2s_v4",
                                "Standard_L2as_v4",
                                "Standard_L2aos_v4",
                                "Standard_L4s_v4",
                                "Standard_L4as_v4",
                                "Standard_L4aos_v4",
                                "Standard_L8s_v4",
                                "Standard_L8as_v4",
                                "Standard_L8aos_v4"
                            ]
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachineScaleSets/sku.capacity",
                            "lessOrEquals": 4
                        },

                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Compute/disks"
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "microsoft.Insights/autoscalesettings"
                        },
                        {
                            "field": "Microsoft.Insights/autoscalesettings/profiles[*].capacity.minimum",
                            "in": [
                                "1",
                                "2"
                            ]
                        },
                        {
                            "field": "Microsoft.Insights/autoscalesettings/profiles[*].capacity.maximum",
                            "in": [
                                "2",
                                "3",
                                "4"
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Compute/virtualMachines/extensions"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.ContainerInstance/containerGroups

> **Purpose**: Allows only one ACI container group named `ca{LabInstance}` using image `aci-helloworld:latest`, 1.5 GB memory, 1 CPU, no GPU, in allowed RG and region. Network is permitted for virtual network integration.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.ContainerInstance/containerGroups"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('ca',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "Microsoft.ContainerInstance/containerGroups/containers[*].image",
                            "contains": "aci-helloworld:latest"
                        },
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
                        {
                            "field": "Microsoft.ContainerInstance/containerGroups/containers[*].resources.requests.memoryInGB",
                            "equals": 1.5
                        },
                        {
                            "field": "Microsoft.ContainerInstance/containerGroups/containers[*].resources.requests.cpu",
                            "equals": 1
                        },
                        {
                            "field": "Microsoft.ContainerInstance/containerGroups/containers[*].resources.requests.gpu.count",
                            "exists": false
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.ContainerRegistry

> **Purpose**: Allows Standard Azure Container Registry named `labregistry{LabInstance}` in allowed RGs and same region. Network is permitted for private endpoint and firewall rule configuration.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.ContainerRegistry/registries"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('labregistry',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "Microsoft.ContainerRegistry/registries/sku.name",
                            "equals": "Standard"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.DataFactory

> **Purpose**: Allows complete ADF solution: factory (`factory{LabInstance}`), managed integration runtime (≤8 cores), linked services (Azure SQL, HTTP), SQL server (`svr{LabInstance}`), and S0 Standard database (≤10 DTU) in allowed RG and region.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.DataFactory/factories"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('factory',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.DataFactory/factories/integrationRuntimes"
                        },
                        {
                            "field": "Microsoft.DataFactory/factories/integrationruntimes/type",
                            "equals": "Managed"
                        },
                        {
                            "field": "Microsoft.DataFactory/factories/integrationRuntimes/Managed.typeProperties.computeProperties.dataFlowProperties.coreCount",
                            "exists": "true"
                        },
                        {
                            "field": "Microsoft.DataFactory/factories/integrationRuntimes/Managed.typeProperties.computeProperties.dataFlowProperties.coreCount",
                            "lessOrEquals": 8
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.DataFactory/factories/linkedservices"
                        },
                        {
                            "field": "Microsoft.DataFactory/factories/linkedservices/type",
                            "in": [
                                "AzureSqlDatabase",
                                "HttpServer"
                            ]
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('svr',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers/databases"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.name",
                            "equals": "S0"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.tier",
                            "equals": "Standard"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.capacity",
                            "lessOrEquals": 10
                        },
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
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.DBforMySQL

> **Purpose**: Allows MySQL Flexible Server named `mysql{LabInstance}` with Burstable tier and approved SKUs (B-series, D-series) in allowed RG and region. Network is required for VNet integration and private endpoint.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.DBforMySQL/flexibleServers"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('mysql',resourceGroup().tags.LabInstance)]"
                        },

                        {
                            "field": "Microsoft.DBForMySql/flexibleServers/sku.tier",
                            "equals": "Burstable"
                        },
                        {
                            "field": "Microsoft.DBForMySql/flexibleServers/sku.name",
                            "in": [
                                "Standard_B2als_v2",
                                "Standard_B2as_v2",
                                "Standard_B2ats_v2",
                                "Standard_B2ls_v2",
                                "Standard_B2ps_v2",
                                "Standard_B2s_v2",
                                "Standard_B2ts_v2",
                                "Standard_B4als_v2",
                                "Standard_B4as_v2",
                                "Standard_B4ls_v2",
                                "Standard_B4ps_v2",
                                "Standard_B4s_v2",
                                "Standard_B8as_v2",
                                "Standard_B8ls_v2",
                                "Standard_B8ps_v2",
                                "Standard_B8s_v2",
                                "Standard_D2ads_v5",
                                "Standard_D2ads_v6",
                                "Standard_D2alds_v6",
                                "Standard_D2als_v6",
                                "Standard_D2as_v4",
                                "Standard_D2as_v5",
                                "Standard_D2as_v6",
                                "Standard_D2ds_v5",
                                "Standard_D2ds_v6",
                                "Standard_D2lds_v5",
                                "Standard_D2lds_v6",
                                "Standard_D2ls_v5",
                                "Standard_D2ls_v6",
                                "Standard_D2s_v3",
                                "Standard_D2s_v4",
                                "Standard_D2s_v5",
                                "Standard_D2s_v6",
                                "Standard_D4ads_v5",
                                "Standard_D4ads_v6",
                                "Standard_D4as_v5",
                                "Standard_D4as_v6",
                                "Standard_D4ds_v5",
                                "Standard_D4ds_v6",
                                "Standard_D4s_v5",
                                "Standard_D4s_v6",
                                "Standard_D8as_v5",
                                "Standard_D8as_v6",
                                "Standard_D8ds_v5",
                                "Standard_D8ds_v6",
                                "Standard_D8s_v5",
                                "Standard_D8s_v6",
                                "Standard_E2ads_v5",
                                "Standard_E2ads_v6",
                                "Standard_E2as_v5",
                                "Standard_E2as_v6",
                                "Standard_E2ds_v5",
                                "Standard_E2ds_v6",
                                "Standard_E2s_v5",
                                "Standard_E2s_v6",
                                "Standard_E4ads_v5",
                                "Standard_E4ads_v6",
                                "Standard_E4as_v5",
                                "Standard_E4as_v6",
                                "Standard_E4ds_v5",
                                "Standard_E4ds_v6",
                                "Standard_E4s_v5",
                                "Standard_E4s_v6",
                                "Standard_E8ads_v5",
                                "Standard_E8ads_v6",
                                "Standard_E8as_v5",
                                "Standard_E8as_v6",
                                "Standard_E8ds_v5",
                                "Standard_E8ds_v6",
                                "Standard_E8s_v5",
                                "Standard_E8s_v6",
                                "Standard_F2s_v2",
                                "Standard_F4s_v2",
                                "Standard_F8s_v2",
                                "Standard_L2s_v4",
                                "Standard_L2as_v4",
                                "Standard_L2aos_v4",
                                "Standard_L4s_v4",
                                "Standard_L4as_v4",
                                "Standard_L4aos_v4",
                                "Standard_L8s_v4",
                                "Standard_L8as_v4",
                                "Standard_L8aos_v4"
                            ]
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.DocumentDB

> **Purpose**: Allows Cosmos DB account named `cdb{LabInstance}` in allowed RG and same region. Network is permitted for private endpoint connectivity.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.DocumentDB/databaseAccounts"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('cdb',resourceGroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.EventGrid/topics

> **Purpose**: Allows Event Grid Topic `egt{LabInstance}` with Standard SKU and capacity ≤20 in allowed RG and region. Storage (as an event destination) and additional EventGrid sub-resources are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.EventGrid/topics"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('egt', resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "Microsoft.EventGrid/topics/sku.name",
                            "equals": "Standard"
                        },
                        {
                            "field": "Microsoft.EventGrid/topics/sku.capacity",
                            "lessOrEquals": 20
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.EventGrid"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.EventGrid/systemTopics

> **Purpose**: Allows System Topics with name `egt{LabInstance}` in allowed RG and matching region. Storage (as an event destination) and additional EventGrid sub-resources are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.EventGrid/systemTopics"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('egt', resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.EventGrid"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.EventHub

> **Purpose**: Allows Event Hubs Namespace `ehn{LabInstance}` with Standard tier and capacity ≤20 in allowed RG and region. Storage (for Event Capture) and additional EventHub sub-resources are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.EventHub/Namespaces"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('ehn',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "Microsoft.EventHub/namespaces/sku.name",
                            "equals": "Standard"
                        },
                        {
                            "field": "Microsoft.EventHub/namespaces/sku.tier",
                            "equals": "Standard"
                        },
                        {
                            "field": "Microsoft.EventHub/namespaces/sku.capacity",
                            "lessOrEquals": 20
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.EventHub"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Network

> **Purpose**: Allows only standard networking resources required for lab deployments. The policy uses an explicit type allowlist (not `contains`) to deny high-cost resources by omission — VPN Gateways, ExpressRoute Circuits, Application Gateways, Azure Firewalls, Bastion Hosts, NAT Gateways, Virtual WAN, and DDoS Protection Plans are all denied because they are not in the list. Public IPs and Load Balancers are further restricted to Basic/Standard SKU only.
>
> **Note**: Per Skillable security guidelines, `Microsoft.Network` is rated **Low risk**. Resource Group and name restrictions are **Recommended** but not Required. Add them when the lab scenario warrants tighter placement control.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "field": "type",
                    "in": [
                        "Microsoft.Network/virtualNetworks",
                        "Microsoft.Network/virtualNetworks/subnets",
                        "Microsoft.Network/networkInterfaces",
                        "Microsoft.Network/networkSecurityGroups",
                        "Microsoft.Network/networkSecurityGroups/securityRules",
                        "Microsoft.Network/privateDnsZones",
                        "Microsoft.Network/privateDnsZones/virtualNetworkLinks",
                        "Microsoft.Network/privateEndpoints",
                        "Microsoft.Network/routeTables"
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Network/publicIPAddresses"
                        },
                        {
                            "field": "Microsoft.Network/publicIPAddresses/sku.name",
                            "in": [
                                "Basic",
                                "Standard"
                            ]
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Network/loadBalancers"
                        },
                        {
                            "field": "Microsoft.Network/loadBalancers/sku.name",
                            "in": [
                                "Basic",
                                "Standard"
                            ]
                        }
                    ]
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.OperationalInsights

> **Purpose**: Allows Log Analytics workspace named `hexeloamlworks*` in allowed RG and region. Azure Monitor (Microsoft.Monitor) and Application Insights (Microsoft.Insights) sub-resources are permitted to support diagnostics and monitoring scenarios.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.OperationalInsights/workspaces"
                        },
                        {
                            "field": "name",
                            "contains": "hexeloamlworks"
                        },
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
                        {
                            "field": "location",
                            "notequals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Insights"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Monitor"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.RecoveryServices

> **Purpose**: Allows Recovery Services Vault named `MyVault{LabInstance}` in allowed RGs (including CSS hyphenated variant) and same region. Network is permitted for backup policy and protected item configuration.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "contains": "Microsoft.RecoveryServices"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('MyVault',resourcegroup().tags.LabInstance)]"
                        },
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
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Search

> **Purpose**: Allows Azure Cognitive Search service `srch{LabInstance}` on `basic` SKU in allowed RG and same region. Storage is permitted for indexer data sources.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Search/searchServices"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('srch',resourceGroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "Microsoft.Search/searchServices/sku.name",
                            "equals": "basic"
                        },

                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Sql/servers

> **Purpose**: Allows SQL servers (`sql{LabInstance}`, `geo{LabInstance}`) and databases (`SalesDB`, `master`) with S0 Standard tier (≤1 DTU) in allowed RG and `westus` or RG region. Network is required for firewall rules and private endpoint configuration.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('sql',resourcegroup().tags.LabInstance)]",
                                "[concat('geo',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers/databases"
                        },
                        {
                            "field": "name",
                            "in": [
                                "SalesDB",
                                "master"
                            ]
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.name",
                            "equals": "S0"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.tier",
                            "equals": "Standard"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.capacity",
                            "lessOrEquals": 1
                        },
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
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```

> *Note*: The "master" database "name" property must always be present in addition to whatever DB name the student will be creating.  
> *Note*: To get the current list of Microsoft.Sql/servers/databases SKU data, run: `Get-AzSqlServerServiceObjective -Location <location>`
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.SqlVirtualMachines

> **Purpose**: Allows SQL VM named `SQLVM1` with Developer or Express edition in allowed RG and region. Storage (for SQL data/log files) and Network (required for the underlying VM infrastructure) are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.SqlVirtualMachine/SqlVirtualMachines"
                        },
                        {
                            "field": "name",
                            "in": [
                                "SQLVM1"
                            ]
                        },
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
                        {
                            "anyOf": [
                                {
                                    "field": "Microsoft.SqlVirtualMachine/SqlVirtualMachines/sqlImageSku",
                                    "in": [
                                        "Express",
                                        "Developer"
                                    ]
                                },
                                {
                                    "field": "Microsoft.SqlVirtualMachine/SqlVirtualMachines/sqlImageSku",
                                    "exists": false
                                }
                            ]
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Synapse

> **Purpose**: Allows full Synapse solution: SQL server (`syn{LabInstance}`), DataWarehouse databases (DW100c, ≤900 capacity), workspace (`synws{LabInstance}`), small Spark pool (Small nodes, ≤10, no autoscale), and supporting Data Factory and Storage. All primary resources are restricted to allowed RG and approved regions.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Synapse/workspaces"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('synws',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Synapse/workspaces/bigDataPools"
                        },
                        {
                            "field": "Microsoft.Synapse/workspaces/bigDataPools/autoScale.enabled",
                            "equals": false
                        },
                        {
                            "field": "Microsoft.Synapse/workspaces/bigDataPools/nodeSize",
                            "equals": "Small"
                        },
                        {
                            "field": "Microsoft.Synapse/workspaces/bigDataPools/nodeCount",
                            "lessOrEquals": 10
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('syn',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Sql/servers/databases"
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.name",
                            "in": [
                                "DataWarehouse",
                                "System",
                                "DW100c"
                            ]
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.tier",
                            "in": [
                                "DataWarehouse",
                                "System",
                                "Free"
                            ]
                        },
                        {
                            "field": "Microsoft.Sql/servers/databases/sku.capacity",
                            "lessOrEquals": 900
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.DataFactory"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Web - Function App

> **Purpose**: Allows Function App `fa-{LabInstance}` with Consumption (Y1) plan named `ASP-corpdata{LODManaged}{LabInstance}`, APIM (`apim{LabInstance}`, Basic/Developer/Consumption), and required Storage. Both `functionapp` and empty `kind` must be present on the serverfarm.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.ApiManagement/service"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('apim',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "Microsoft.ApiManagement/service/sku.name",
                            "in": [
                                "Basic",
                                "Developer",
                                "Consumption"
                            ]
                        },
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
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Web/serverfarms"
                        },
                        {
                            "field": "kind",
                            "in": [
                                "functionapp",
                                ""
                            ]
                        },
                        {
                            "field": "Microsoft.Web/serverFarms/sku.name",
                            "in": [
                                "Y1"
                            ]
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.capacity",
                            "lessOrEquals": 1
                        },
                        {
                            "field": "name",
                            "contains": "[concat('ASP-corpdata',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance)]"
                        },

                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Web/sites"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('fa-',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageaccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "Deny"
    }
}
```

> *Note*: When a "function app" is being created, the "kind" - "functionapp" AND the blank value must be present.
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Web/serverfarms

> **Purpose**: Allows B1/S1 App Service Plan named `asp-AIApp{LabInstance}` for AI app deployments (e.g., OpenAI Chat Playground). Storage and Network are permitted for app content and VNet integration.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.web/serverfarms"
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.name",
                            "in": [
                                "B1",
                                "S1"
                            ]
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.capacity",
                            "lessOrEquals": 1
                        },
                        {
                            "field": "name",
                            "equals": "[concat('asp-AIApp',resourcegroup().tags.LabInstance)]"
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "deny"
    }
}
```

> *Note*: This is for when creating a web app through the Chat Playground in an OpenAI service.  
> *Note*: Do not include the `field: id` restriction when `Microsoft.web/serverfarms` is deployed as a web app from an OpenAI service (chat playground), as the deployment originates outside the lab RG context.  
> *Note*: From Azure: "If the value of the kind property is null, empty, or not on this list, the portal treats the resource as Web App."
---
[Back to TOC:](#table-of-contents)
<br><br>

## Microsoft.Web/sites

> **Purpose**: Allows Function App site `fa-{LabInstance}` and its Dynamic/S1 App Service Plan `dataASP` in allowed RG and region. Storage (required by Function Apps) and Network are permitted.

```json
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.Web/sites"
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('fa-',resourcegroup().tags.LabInstance)]"
                            ]
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.web/serverfarms"
                        },
                        {
                            "field": "kind",
                            "in": [
                                "functionapp",
                                ""
                            ]
                        },
                        {
                            "field": "name",
                            "equals": "dataASP"
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.name",
                            "equals": "S1"
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.tier",
                            "equals": "Dynamic"
                        },
                        {
                            "field": "Microsoft.web/serverfarms/sku.capacity",
                            "lessOrEquals": 1
                        },
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
                        {
                            "field": "location",
                            "notEquals": "global"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
                }
            ]
        }
    },
    "then": {
        "effect": "deny"
    }
}
```

> *Note*: The empty quotes `""` in `field: kind` are necessary.
---
[Back to TOC:](#table-of-contents)
<br><br>
