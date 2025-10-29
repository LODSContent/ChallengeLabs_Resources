# Skillable Compliant Azure ACP Reference

## Resource Group id Examples

```
{
    "field": "id",
    "contains": "[concat('/resourceGroups/corp-data',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
}
```

> **Purpose**: Allows resources only in dynamically generated resource groups using `corp-data` prefix and tags `LODManaged` and `LabInstance`.

```
{
    "field": "id",
    "contains": "/resourceGroups/rg1/"
}
```

> **Purpose**: Restricts resources to a static resource group named `rg1`.

> *Note*: `//using dynamically generated RG name`  
> *Note*: `// using a static RG name`  
> *Note*: `// Allowing CSS and CSR variations in the same ACP. This should be used whenever possible.`

```
{
    "anyOf": [
        {
            "field": "id",
            "contains": "/resourceGroups/RG1/"
        },
        {
            "field": "id",
            "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
        },
        {
            "field": "id",
            "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
        }
    ]
}
```

## Location (region) examples

```
{
    "field": "location",
    "In": [
        "[resourceGroup().location]"
    ]
}
```

> **Purpose**: Ensures resources are created in the same region as their resource group.

```
{
    "field": "location",
    "notEquals": "global"
}
```

> **Purpose**: Prevents use of the `global` region (required for regional resources).

```
{
    "field": "location",
    "In": [
        "eastus2",
        "[resourceGroup().location]"
    ]
}
```

> **Purpose**: Allows deployment in `eastus2` or the resource group’s location.

```
{
    "field": "location",
    "notEquals": "global"
}
```

> *Note*: `// location based upon the location of the current resource group`  
> *Note*: `// Allowing alternate locations`

## Microsoft.App/containerApps

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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
                        {
                            "field": "location",
                            "In": [
                                "[resourceGroup().location]"
                            ]
                        }
                    ]
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
                    "contains": "Microsoft.EventHub"
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

> **Purpose**: Permits only specific Container Apps and Managed Environments with naming conventions tied to `LabInstance`, in allowed RGs and regions. Allows supporting resources.

## Microsoft.CognitiveServices

```
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
                            "in": [
                                "ImmersiveReader",
                                "TextTranslation"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('hexelo-immersive',resourcegroup().tags.LabInstance)]",
                                "[concat('TranslationService',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "in": [
                                "S",
                                "S0",
                                "S1",
                                "F0"
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
                    "contains": "Microsoft.EventHub"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows only Immersive Reader and Text Translation Cognitive Services with specific names and SKUs.

```
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
                            "in": [
                                "[concat('search-realestate',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "Microsoft.Search/searchServices/sku.name",
                            "in": [
                                "basic"
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
                    "contains": "Microsoft.EventHub"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Restricts Azure Cognitive Search to a specific named service on the `basic` SKU.

```
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.MachineLearningServices/workspaces"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('HexeloAML-workspace',resourcegroup().tags.LabInstance)]"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "equals": "Microsoft.MachineLearningServices/workspaces/computes"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('hexelo-aai-mls',resourcegroup().tags.LabInstance)]"
                        }
                    ]
                },
                {
                    "field": "type",
                    "equals": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "equals": "Microsoft.KeyVault/vaults"
                },
                {
                    "field": "type",
                    "equals": "Microsoft.OperationalInsights/workspaces"
                },
                {
                    "field": "type",
                    "equals": "Microsoft.Insights/components"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows only a specific AML workspace and compute instance, plus required supporting services (Storage, Key Vault, Log Analytics, App Insights).

```
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
                            "in": [
                                "TextAnalytics",
                                "FormRecognizer",
                                "ComputerVision"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('Hexelo-Doc-Intel',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "in": [
                                "S",
                                "S0",
                                "S1",
                                "F0"
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "equals": "Microsoft.Storage/storageAccounts"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Permits Document Intelligence (Text Analytics, Form Recognizer, Computer Vision) under a specific name and SKU, with Storage.

```
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
                            "in": [
                                "ComputerVision"
                            ]
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "in": [
                                "S",
                                "F0"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('AITan-', resourceGroup().tags.labInstance)]",
                                "[concat('ExtractiveSummarization', resourceGroup().tags.labInstance)]",
                                "[concat('ComputerVision', resourceGroup().tags.labInstance)]"
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "equals": "Microsoft.CognitiveServices/accounts/deployments"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows specific Computer Vision instances and their deployments.

```
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
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "in": [
                                "S",
                                "F0",
                                "S1",
                                "S0"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('VisionResource', resourceGroup().tags.labInstance)]",
                                "[concat('ComputerVision', resourceGroup().tags.labInstance)]"
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "equals": "Microsoft.CognitiveServices/accounts/deployments"
                },
                {
                    "field": "type",
                    "equals": "Microsoft.Storage/storageAccounts"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows Vision-related Cognitive Services and supporting storage/deployments.

```
{
    "if": {
        "not": {
            "anyOf": [
                {
                    "allOf": [
                        {
                            "field": "type",
                            "contains": "Microsoft.CognitiveServices"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('OpenAI',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "Microsoft.CognitiveServices/accounts/sku.name",
                            "equals": "S0"
                        },
                        {
                            "field": "kind",
                            "equals": "OpenAI"
                        }
                    ]
                },
                {
                    "allOf": [
                        {
                            "field": "type",
                            "contains": "Microsoft.Search/searchServices"
                        },
                        {
                            "field": "name",
                            "equals": "[concat('azuresearch',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "Microsoft.Search/searchServices/sku.name",
                            "equals": "basic"
                        }
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageaccounts"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows OpenAI and Azure Cognitive Search with specific names and SKUs, plus storage.

## Microsoft.Automation

```
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
            "field": "Microsoft.Automation/automationAccounts/sku.name",
            "equals": "Basic"
        },
        {
            "field": "Microsoft.Automation/automationAccounts/sku.capacity",
            "exists": "false"
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
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
    ]
}
```

> **Purpose**: Allows Automation Accounts with specific names, Basic SKU, no capacity, in allowed RGs and regions.

```
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
                "azureautomationtutorialwithidentitygraphical",
                "azureautomationtutorialwithidentity"
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
}
```

> **Purpose**: Permits specific runbooks of allowed types within approved Automation Accounts.

```
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.Automation/automationAccounts"
        },
        {
            "field": "name",
            "like": "remoterec-*-asr-automationaccount"
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
            "anyOf": [
                {
                    "field": "id",
                    "contains": "/resourceGroups/RG1/"
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                },
                {
                    "field": "id",
                    "contains": "/resourceGroups/RG2/"
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG2',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "location",
            "In": [
                "eastus",
                "westus2",
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows ASR recovery Automation Accounts in multiple RGs and regions.

> *Note*: `------------------------------------`

## Microsoft.Compute/virtualMachines

```
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
                                "Standard_B1s", "Standard_B1ls", "Standard_B1ms", "Standard_B4ms", "Standard_B2ats_v2", "Standard_B2ts_v2", "Standard_B2als_v2", "Standard_B2ls_v2", "Standard_B2as_v2", "Standard_B2ms", "Standard_B2s", "Standard_B2s_v2", "Standard_B2ts_v2", "Standard_B4als_v2", "Standard_B4ls_v2", "Standard_B4as_v2", "Standard_B4ms", "Standard_B4s_v2", "Standard_D2als_v6", "Standard_D2ls_v6", "Standard_D2as_v6", "Standard_D2alds_v6", "Standard_D2S_v3", "Standard_D2s_v4", "Standard_D2s_v6", "Standard_D3_v1", "Standard_D3_v2", "Standard_DS1_v2", "Standard_DS3_v2"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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

> **Purpose**: Allows only approved VM SKUs and names in allowed RGs and regions.

## Microsoft.Compute/virtualMachineScaleSets

```
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
                                "Standard_B1s", "Standard_B1ls", "Standard_B1ms", "Standard_B4ms", "Standard_B2ats_v2", "Standard_B2ts_v2", "Standard_B2als_v2", "Standard_B2ls_v2", "Standard_B2as_v2", "Standard_B2ms", "Standard_B2s", "Standard_B2s_v2", "Standard_B2ts_v2", "Standard_B4als_v2", "Standard_B4ls_v2", "Standard_B4as_v2", "Standard_B4ms", "Standard_B4s_v2", "Standard_D2als_v6", "Standard_D2ls_v6", "Standard_D2as_v6", "Standard_D2alds_v6", "Standard_D2S_v3", "Standard_D2s_v4", "Standard_D2s_v6", "Standard_D3_v1", "Standard_D3_v2", "Standard_DS1_v2", "Standard_DS3_v2"
                            ]
                        },
                        {
                            "field": "name",
                            "in": [
                                "[concat('vm',resourcegroup().tags.LabInstance,'jbox')]"
                            ]
                        },
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
                                "Standard_B1s", "Standard_B1ls", "Standard_B1ms", "Standard_B4ms", "Standard_B2ats_v2", "Standard_B2ts_v2", "Standard_B2als_v2", "Standard_B2ls_v2", "Standard_B2as_v2", "Standard_B2ms", "Standard_B2s", "Standard_B2s_v2", "Standard_B2ts_v2", "Standard_B4als_v2", "Standard_B4ls_v2", "Standard_B4as_v2", "Standard_B4ms", "Standard_B4s_v2", "Standard_D2als_v6", "Standard_D2ls_v6", "Standard_D2as_v6", "Standard_D2alds_v6", "Standard_D2S_v3", "Standard_D2s_v4", "Standard_D2s_v6", "Standard_D3_v1", "Standard_D3_v2", "Standard_DS1_v2", "Standard_DS3_v2"
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
                            "In": [
                                "[resourceGroup().location]"
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
                            "field": "Microsoft.Compute/virtualMachineScaleSets/sku.name",
                            "in": [
                                "Standard_B1s", "Standard_B1ls", "Standard_B1ms", "Standard_B4ms", "Standard_B2ats_v2", "Standard_B2ts_v2", "Standard_B2als_v2", "Standard_B2ls_v2", "Standard_B2as_v2", "Standard_B2ms", "Standard_B2s", "Standard_B2s_v2", "Standard_B2ts_v2", "Standard_B4als_v2", "Standard_B4ls_v2", "Standard_B4as_v2", "Standard_B4ms", "Standard_B4s_v2", "Standard_D2als_v6", "Standard_D2ls_v6", "Standard_D2as_v6", "Standard_D2alds_v6", "Standard_D2S_v3", "Standard_D2s_v4", "Standard_D2s_v6", "Standard_D3_v1", "Standard_D3_v2", "Standard_DS1_v2", "Standard_DS3_v2"
                            ]
                        },
                        {
                            "field": "Microsoft.Compute/virtualMachineScaleSets/sku.capacity",
                            "lessOrEquals": 4
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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

> **Purpose**: Allows VMSS and member VMs with specific naming, SKUs, scale limits, and supporting resources.

## Microsoft.ContainerInstance/containerGroups

```
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
                            "field": "location",
                            "In": [
                                "[resourceGroup().location]"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
                    "contains": "Microsoft.Storage/storageAccounts"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.EventHub"
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

> **Purpose**: Allows only a specific ACI container group with `aci-helloworld`, fixed CPU/memory, no GPU.

## Microsoft.ContainerRegistry

```
{
    "allOf": [
        {
            "field": "type",
            "equals": "Microsoft.ContainerRegistry/registries"
        },
        {
            "field": "name",
            "like": "crpyritlab*"
        },
        {
            "field": "Microsoft.ContainerRegistry/registries/sku.name",
            "equals": "Premium"
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "location",
            "equals": "[resourceGroup().location]"
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows Premium ACR with names starting `crpyritlab` in allowed RGs and regions.

## Microsoft.DataFactory

```
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
                            "field": "location",
                            "equals": "[resourceGroup().location]"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
                        {
                            "field": "location",
                            "equals": "[resourceGroup().location]"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
                    "contains": "Microsoft.EventHub"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows a full ADF solution: factory, managed IR, linked services, SQL server, S0 database.

## Microsoft.DBforMySQL

```
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
                            "anyOf": [
                                {
                                    "field": "id",
                                    "contains": "/resourceGroups/RG1/"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
                        {
                            "field": "Microsoft.DBForMySql/flexibleServers/sku.tier",
                            "equals": "Burstable"
                        },
                        {
                            "field": "Microsoft.DBForMySql/flexibleServers/sku.name",
                            "in": [
                                "Standard_B1s", "Standard_B1ls", "Standard_B1ms", "Standard_B4ms", "Standard_B2ats_v2", "Standard_B2ts_v2", "Standard_B2als_v2", "Standard_B2ls_v2", "Standard_B2as_v2", "Standard_B2ms", "Standard_B2s", "Standard_B2s_v2", "Standard_B2ts_v2", "Standard_B4als_v2", "Standard_B4ls_v2", "Standard_B4as_v2", "Standard_B4ms", "Standard_B4s_v2", "Standard_D2als_v6", "Standard_D2ls_v6", "Standard_D2as_v6", "Standard_D2alds_v6", "Standard_D2S_v3", "Standard_D2s_v4", "Standard_D2s_v6", "Standard_D3_v1", "Standard_D3_v2", "Standard_DS1_v2", "Standard_DS3_v2"
                            ]
                        },
                        {
                            "field": "location",
                            "equals": "[resourceGroup().location]"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows MySQL Flexible Server with burstable tier and specific SKUs.

## Microsoft.DocumentDB

```
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "location",
            "equals": "[resourceGroup().location]"
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows Cosmos DB account with specific naming in allowed region and RG.

## Microsoft.EventGrid/topics

```
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows Event Grid Topic with Standard SKU and capacity ≤20.

## Microsoft.EventGrid/systemTopics

```
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "location",
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows System Topics with matching name and region.

## Microsoft.EventHub

```
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows Event Hubs Namespace with Standard tier and capacity ≤20.

## Microsoft.OperationalInsights

```
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
            "field": "Microsoft.OperationalInsights/workspaces/sku.name",
            "exists": "false"
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "location",
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notequals": "global"
        }
    ]
}
```

> **Purpose**: Allows Log Analytics workspace with name containing `hexeloamlworks`.

## Microsoft.Search

```
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
            "field": "Microsoft.Search/searchServices/sku.name",
            "equals": "basic"
        },
        {
            "field": "location",
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows Azure Cognitive Search on Basic SKU with specific name.

## Microsoft.Sql/servers

```
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
                        {
                            "field": "location",
                            "in": [
                                "westus",
                                "[resourceGroup().location]"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        }
                    ]
                },
                {
                    "field": "type",
                    "in": [
                        "Microsoft.Network/storageAccounts",
                        "Microsoft.DBforMySQL/servers/firewallRules"
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

> **Purpose**: Allows SQL servers and S0 databases (`SalesDB`, `master`) in `westus` or RG region.

> *Note*: The “master” database “name” property must always be present in addition to whatever DB name the student will be creating.  
> *Note*: To get the current list of Microsoft.Sql/servers/databases Sku Data, run the following command:  
> o   Get-AzSqlServerServiceObjective -Location <location>

## Microsoft.SqlVirtualMachines

```
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
                },
                {
                    "field": "id",
                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                }
            ]
        },
        {
            "field": "properties.sqlImageSku",
            "equals": "Developer"
        },
        {
            "field": "location",
            "in": [
                "[resourceGroup().location]"
            ]
        },
        {
            "field": "location",
            "notEquals": "global"
        }
    ]
}
```

> **Purpose**: Allows SQL VM with Developer edition and name `SQLVM1`.

## Microsoft.Synapse

```
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
                            "equals": "[concat('syn',resourcegroup().tags.LabInstance)]"
                        },
                        {
                            "field": "location",
                            "in": [
                                "[resourceGroup().location]",
                                "eastus",
                                "eastus2"
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
                            "in": [
                                "[resourceGroup().location]",
                                "eastus",
                                "eastus2"
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
                    "field": "type",
                    "contains": "Microsoft.DataFactory"
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
                    "contains": "Microsoft.EventGrid"
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Network"
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

> **Purpose**: Allows full Synapse workspace with SQL DW, Spark pool (Small, ≤10 nodes), and supporting services.

## Microsoft.Web - Function App

```
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
                            "anyOf": [
                                {
                                    "field": "id",
                                    "contains": "/resourceGroups/RG1/"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
                            "anyOf": [
                                {
                                    "field": "id",
                                    "contains": "/resourceGroups/RG1/"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageaccounts"
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

> **Purpose**: Allows Function App with Y1 plan, APIM, and storage.

> *Note*: When a “function app” is being created, the “kind” - “functionapp” AND the blank value must be present.

## Microsoft.Web/serverfarms

```
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
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
                            "equals": "[concat('ASP-corpdata',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance)]"
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
                            "anyOf": [
                                {
                                    "field": "id",
                                    "contains": "/resourceGroups/RG1/"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
                    ]
                },
                {
                    "field": "type",
                    "contains": "Microsoft.Storage/storageaccounts"
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

> **Purpose**: Allows App Service Plan for Function Apps (Y1, dynamic).

> *Note*: From Azure: “If the value of the kind property is null, empty, or not on this list, the portal treats the resource as Web App.”

## Microsoft.Web/sites

```
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
                                },
                                {
                                    "field": "id",
                                    "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
                                }
                            ]
                        },
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows Function App site and its S1 Dynamic App Service Plan.

> *Note*: Notes: the empty quotes "" in field: kind are necessary.

## Microsoft.web/serverfarms

```
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
                            "field": "location",
                            "in": [
                                "[resourceGroup().location]"
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
                    "contains": "Microsoft.EventHub"
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
        "effect": "deny"
    }
}
```

> **Purpose**: Allows B1/S1 App Service Plan for AI apps (e.g., OpenAI Chat Playground).

> *Note*: Note: this is for when creating a web app through the Chat Playground in an OpenAI service.  
> *Note*: Note: Do not include the field: id when Microsoft.web/serverfarms is deployed as a web app from an OpenAI service (chat playground).
```
