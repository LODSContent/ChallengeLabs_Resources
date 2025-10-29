# Skillable Compliant Azure ACP Reference

## Resource Group id Examples

<details class="purpose">
  <summary>Purpose: Restrict resource placement using dynamic or static Resource Group IDs</summary>
  <div>
    These policies are foundational fragments used in combination with others. They define allowed Resource Group patterns using either:
    <ul>
      <li>Dynamic naming via <code>corp-data</code> + tags <code>LODManaged</code> and <code>LabInstance</code></li>
      <li>Static name <code>rg1</code></li>
      <li>Multiple allowed RG patterns (RG1, tagged variants)</li>
    </ul>
  </div>
</details>

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
        },
        {
            "field": "id",
            "contains": "[concat('/resourceGroups/RG1-',resourcegroup().tags.LODManaged,resourcegroup().tags.LabInstance,'/')]"
        }
    ]
}
```

> *Note*: `// Allowing CSS and CSR variations in the same ACP. This should be used whenever possible.`

## Location (region) examples

<details class="purpose">
  <summary>Purpose: Enforce regional compliance and prevent invalid location usage</summary>
  <div>
    Ensures resources are deployed in:
    <ul>
      <li>The same region as their Resource Group (<code>[resourceGroup().location]</code>)</li>
      <li>Never in the <code>global</code> region (invalid for regional resources)</li>
      <li>Optionally allows <code>eastus2</code> as an alternate approved region</li>
    </ul>
    Prevents deployment drift and ensures consistent regional strategy.
  </div>
</details>

```json
{
    "field": "location",
    "In": [
        "[resourceGroup().location]"
    ]
}
```

```json
{
    "field": "location",
    "notEquals": "global"
}
```

```json
{
    "field": "location",
    "In": [
        "eastus2",
        "[resourceGroup().location]"
    ]
}
```

```json
{
    "field": "location",
    "notEquals": "global"
}
```

> *Note*: `// location based upon the location of the current resource group`  
> *Note*: `// Allowing alternate locations`

## Microsoft.App/containerApps

<details class="purpose">
  <summary>Purpose: Allow only approved Container Apps and Managed Environments with strict naming and placement</summary>
  <div>
    Permits:
    <ul>
      <li><code>Microsoft.App/containerApps</code> named <code>ca{LabInstance}</code></li>
      <li><code>Microsoft.App/managedEnvironments</code> named <code>env{LabInstance}</code></li>
      <li>Placement only in allowed RGs and matching region</li>
      <li>Supporting resources (Storage, EventHub, EventGrid, Network)</li>
    </ul>
    Blocks all other Container Apps or unmanaged deployments.
  </div>
</details>

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

## Microsoft.CognitiveServices

<details class="purpose">
  <summary>Purpose: Restrict Cognitive Services to approved kinds, names, and SKUs</summary>
  <div>
    Allows only:
    <ul>
      <li><strong>ImmersiveReader</strong> and <strong>TextTranslation</strong> services</li>
      <li>Names: <code>hexelo-immersive{LabInstance}</code>, <code>TranslationService{LabInstance}</code></li>
      <li>SKUs: S, S0, S1, F0</li>
      <li>Supporting Storage, EventHub, EventGrid, Network</li>
    </ul>
    All other Cognitive Services kinds are denied.
  </div>
</details>

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

<details class="purpose">
  <summary>Purpose: Allow only specific Azure Cognitive Search instance</summary>
  <div>
    Permits one search service:
    <ul>
      <li>Name: <code>search-realestate{LabInstance}</code></li>
      <li>SKU: <code>basic</code></li>
      <li>Supporting infrastructure allowed</li>
    </ul>
  </div>
</details>

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
                            "in": [
                                "[concat('search-realestate',resourcegroup().tags.LabInstance)]"
                            ]
                        },
                       : [
                            "basic"
                        ]
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

<details class="purpose">
  <summary>Purpose: Allow AML workspace and compute with required supporting services</summary>
  <div>
    Permits:
    <ul>
      <li>Workspace: <code>HexeloAML-workspace{LabInstance}</code></li>
      <li>Compute: <code>hexelo-aai-mls{LabInstance}</code></li>
      <li>Supporting: Storage, Key Vault, Log Analytics, App Insights</li>
    </ul>
  </div>
</details>

```json
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

<!-- Continue with remaining policies in the same pattern -->

<!-- Example continuation for Microsoft.CognitiveServices Document Intelligence -->

<details class="purpose">
  <summary>Purpose: Allow Document Intelligence services (Text Analytics, Form Recognizer, Computer Vision)</summary>
  <div>
    Allows:
    <ul>
      <li>Kind: TextAnalytics, FormRecognizer, ComputerVision</li>
      <li>Name: <code>Hexelo-Doc-Intel{LabInstance}</code></li>
      <li>SKUs: S, S0, S1, F0</li>
      <li>Storage support</li>
    </ul>
  </div>
</details>

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

