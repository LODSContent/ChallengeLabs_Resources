<#
   Title: Remove Open AI Deployments (CSR)
   Description: Script to remove Azure Open AI deployments in a CSR subscription.
   Target: Cloud Subscription | PS 7.5.5 | Az 15.6.0
   Template: 5.0
   Version: 2026-06-02-1609
#>

$LabInstanceId = "@lab.LabInstance.Id"
$resourceGroups = Get-AzResourceGroup | Where-Object { $_.ResourceGroupName -match $LabInstanceId }

# Query for all OpenAI deployment accounts in the discovered resource groups and store them in an array.
$AIObjs = @()
$AIObjArray = @()
foreach ($resourceGroup in $resourceGroups) {
    $rgAccounts = Get-AzResource -ResourceType "Microsoft.CognitiveServices/accounts" -ResourceGroupName $resourceGroup.ResourceGroupName
    $AIObjs += $rgAccounts
    foreach ($AIobj in $rgAccounts) {
        $AIObjArray += Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $AIobj.ResourceGroupName -AccountName $AIobj.Name
    }
}

# Loop through each model deployment and delete it
foreach ($Deployment in $AIObjArray) {
    Remove-AzCognitiveServicesAccountDeployment -ResourceId $Deployment.Id -Force
}

# Loop through accounts & delete nested Projects
foreach ($account in $AIObjs) {
    $nestedProjects = Get-AzResource -ResourceType "Microsoft.CognitiveServices/accounts/projects" `
        -ResourceGroupName $account.ResourceGroupName
    foreach ($project in $nestedProjects) {
        Remove-AzResource -ResourceId $project.ResourceId -Force
        Write-Output "Deleted nested project: $($project.Name)"
    }
}

# Capture account names before deletion so we can target only this instance's soft-deleted accounts during purge
$accountNames = $AIObjs | Select-Object -ExpandProperty Name

# Loop through each OpenAI account and delete it
foreach ($account in $AIObjs) {
    Remove-AzResource -ResourceId $account.ResourceId -Force
    Write-Output "Deleted OpenAI account: $($account.Name)"
}

# Purge soft-deleted accounts that belonged to this instance — filter by name to avoid
# targeting accounts from other instances sharing this subscription
$subId = (Get-AzContext).Subscription.Id
Start-Sleep -Seconds 15
$deletedAccounts = Get-AzResource -ResourceId "/subscriptions/$subId/providers/Microsoft.CognitiveServices/deletedAccounts" -ApiVersion 2024-10-01
foreach ($deleted in $deletedAccounts) {
    if ($accountNames -contains $deleted.Name) {
        Remove-AzResource -ResourceId $deleted.ResourceId -ApiVersion 2024-10-01 -Force
        Write-Output "Purged soft-deleted account: $($deleted.Name)"
    }
}
