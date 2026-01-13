<#
   Title: Dynamic VM Sizer Launcher
   Description: Use this script in a Lifecycle Action to launch the DynamicVMSizer.ps1 script located in GitHub.
                The script will discover available VM Sizes (SKUs) and find one that is at least the same size 
                or larger than the Target size.
                Create a VMTargetSpec1 lab variable in the lab profile and populate with the desired size using
                the format below.
                The script will create a VMSize1 lab variable with the resulting size (SKU) that is found.
                The resulting VMSize1 variable can be used in lab instructions or Resource Template Parameters.
                The resource group lab variable MUST be specified below for the "Location". 
   Target: Pre-Build - Blocking - Cloud Subscription - PowerShell - 7.4.0 | Az 11.1.0 (RC)
   Version: 2026.01.13
#>

# Define the parameters in a hash table
$params = @{
    # Target VM Size - Format: c<cpu>r<ram>g<gen>p<price-0.00> e.g. c2r4g2p0.20, c4r16g1p0.70
    TargetSpec = '@lab.Variable(VMTargetSpec1)'
    
    # Name of the @lab variable to return
    VMSizeLabVariable = 'VMSize1'
    
    # Location (from the resource group)
    Location = '@lab.CloudResourceGroup(RG1).Location'
    
    ### Uncomment the following parameters to override script defaults.
    
    # URL for allowed list of VM sizes (SKUs)
    #allowedSizesURL = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs/AzureVMSizes.csv"
    
    # Default size to use if automatic selection fails
    #DefaultSize = 'Standard_B4as_v2'
    
    # Maximum allowed vCPUs
    #MaxCPU = '16'
    
    # Maximum allowed RAM in GB
    #MaxRAM = '64'
    
    # Enable script debugging by setting the debug lab variable to True
    ScriptDebug = ('@lab.Variable(debug)' -in 'Yes','True' -or '@lab.Variable(Debug)' -in 'Yes','True')
}

# URL of the script on GitHub
$scriptUrl = "https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/refs/heads/master/LCAs/DynamicVMSizer.ps1"

# Initialize variables for retry logic
$maxRetries = 10
$retryDelay = 5  # seconds
$attempt = 1
$scriptContent = $null

# Attempt to download the script content with retries
while ($attempt -le $maxRetries -and $null -eq $scriptContent) {
    try {
        $scriptContent = (Invoke-WebRequest -Uri $scriptUrl -UseBasicParsing -ErrorAction Stop).Content
    }
    catch {
        if ($attempt -eq $maxRetries) {
            Throw "Failed to download script: '$scriptUrl' from GitHub after $maxRetries attempts: $_"
        }
        Start-Sleep -Seconds $retryDelay
        $attempt++
    }
}

# Create a script block from the downloaded content
$scriptBlock = [ScriptBlock]::Create($scriptContent)

# Execute the script block with parameters
$result = & $scriptBlock @Params

return $result
