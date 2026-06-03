<#
   Title: Tear down Open AI deployments and Accounts (CSS)
   Description: Script to remove Open AI resources at lab teardown to reduce ongoing cost.
   Target: Cloud Subscription | PS 7.4.0 | Az 11.1.0 (RC)
   Timeout: 10 min
   Template: 5.0
   Version: 2026-06-02-1609
#>

# Query for all OpenAI deployment accounts in the subscription or resource group, depending on the context scope.
$AIObjs = Get-AzResource -ResourceType "Microsoft.CognitiveServices/accounts" 
# Get the model deployments for each OpenAI account and store them in an array
$AIObjArray = @()
foreach ($AIobj in $AIObjs) {
$AIObjArray += Get-AzCognitiveServicesAccountDeployment -ResourceGroupName $AIobj.ResourceGroupName -AccountName $AIobj.Name
}
#Loop through each model deployment and delete it
foreach ($Deployment in $AIObjArray) {
    Remove-AzCognitiveServicesAccountDeployment -ResourceId $deployment.Id -Force    
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
# Loop through each Open AI deployment account and delete it
foreach ($account in $AIObjs) {
    Remove-AzResource -ResourceId $account.ResourceId -Force
    Write-Output "Deleted OpenAI deployment: $($account.Name)"
}
# Purge each soft-deleted account so the name & regional quota are freed
$subId = (Get-AzContext).Subscription.Id
Start-Sleep -Seconds 15
$deletedAccounts = Get-AzResource -ResourceId "/subscriptions/$subId/providers/Microsoft.CognitiveServices/deletedAccounts" -ApiVersion 2024-10-01
foreach ($deleted in $deletedAccounts) {
    Remove-AzResource -ResourceId $deleted.ResourceId -ApiVersion 2024-10-01 -Force
    Write-Output "Purged soft-deleted account: $($deleted.Name)"
}
