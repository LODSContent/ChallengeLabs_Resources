# IISWebSite.ps1
# Simple IIS setup script for Azure Custom Script Extension

Write-Output "Starting IIS Web Server configuration on $env:COMPUTERNAME..."

# Install required Windows features
Install-WindowsFeature -Name Web-Server -IncludeManagementTools -ErrorAction Stop
Install-WindowsFeature -Name Web-Asp-Net45 -ErrorAction Stop
Install-WindowsFeature -Name Web-Mgmt-Console -ErrorAction Stop

Write-Output "Windows Features installed successfully."

# Download and configure index.html
$indexPath = 'C:\inetpub\wwwroot\index.html'

if (-not (Test-Path $indexPath)) {
    Write-Output "Downloading index.html..."
    Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_ArmResources/master/DSCResources/SimpleIIS/Index.html' `
                      -OutFile $indexPath -UseBasicParsing
    Unblock-File -Path $indexPath
}

# Replace placeholder with actual computer name
$content = Get-Content -Path $indexPath -Raw
if ($content -notmatch [regex]::Escape($env:COMPUTERNAME)) {
    Write-Output "Updating index.html with computer name..."
    $content = $content -replace 'WebServer', $env:COMPUTERNAME
    Set-Content -Path $indexPath -Value $content -Force
}

# Restart IIS to apply changes
Restart-Service -Name W3SVC -Force

Write-Output "IIS Web Site configuration completed successfully on $env:COMPUTERNAME."
