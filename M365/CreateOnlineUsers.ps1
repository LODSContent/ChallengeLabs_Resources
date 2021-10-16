$msolcred=Get-Credential
Connect-MsolService -Credential $msolcred
Connect-AzureAD -Credential $msolcred

#Get tenant domain and create variable for use later in script

$dn = "@" + (get-msoldomain).name

#Create users and, optionally, ensure they are assigned appropriate licences

Import-Csv D:\LabFiles\onlineusers.csv | foreach {New-MsolUser -UserPrincipalName ($_.SAM + "$dn")  -DisplayName "$($_.DisplayName)" -FirstName "$($_.Fname)" -LastName "$($_.Lname)" -Department "$($_.Department)" -City "$($_.City)" -State "$($_.State)" -Title "$($_.Title)"-Password 'Passw0rd!' -PasswordNeverExpires $true -ForceChangePassword $false -UsageLocation "US"}  
Get-Msoluser -All | where {$_.usagelocation -eq $null} | Set-MsolUser -UsageLocation US
# Get-MsolUser | where {$_.isLicensed -eq $false} | Set-MsolUserLicense -AddLicenses (Get-MsolAccountSku).AccountSkuId

#Create groups

New-AzureADGroup -DisplayName "Mobile Users" -MailEnabled $false -SecurityEnabled $true -MailNickName "MobileUsers"
New-AzureADGroup -DisplayName "Managers" -MailEnabled $false -SecurityEnabled $true -MailNickName "Managers"
New-AzureADGroup -DisplayName "Regular Employees" -MailEnabled $false -SecurityEnabled $true -MailNickName "RegularEmployees"


#Pause for 30 seconds to ensure Azure AD objects are properly populated

sleep -Seconds 30

# Get group Object ID Guids and place them in variables

$MobileUsersGUID = (Get-AzureADGroup -Filter "DisplayName eq 'Mobile Users'").ObjectId
$ManagersGUID = (Get-AzureADGroup -Filter "DisplayName eq 'Managers'").ObjectId
$RegularEmployeesGUID = (Get-AzureADGroup -Filter "DisplayName eq 'Regular Employees'").ObjectId


#Get array of Object IDs for all newly created users and create variable for array

$NewUserIDs=(Get-AzureADUser | where {$_.department -ne $null}).ObjectID

#Get array of Object IDs for all managers and create variable for array

$ManagerIDs=(Get-AzureADUser | where {$_.JobTitle -eq "Manager"}).ObjectID

#Get array of Object IDs for all regulare employees and create variable for array

$StaffIDs=(Get-AzureADUser | where {$_.JobTitle -ne "Manager" -and $_.department -ne $null}).ObjectID

# Iterate through arrays and populate groups with respective members

Foreach ($ID in $NewUserIDs) {
 Add-AzureADGroupMember -ObjectId $MobileUsersGUID -RefObjectId $ID
 }

 Foreach ($ID in $ManagerIDs) {
 Add-AzureADGroupMember -ObjectId $ManagersGUID -RefObjectId $ID
 }

 Foreach ($ID in $StaffIDs) {
 Add-AzureADGroupMember -ObjectId $RegularEmployeesGUID -RefObjectId $ID
 }



 
 # During beta testing of lab, it was discovered that, in some instances, groups
 # were not properly populated with any members or too few members. 
 # The cause is likely related to timing issues in Azure AD. So, this portion
 # of the script attempts to address the potential issue with a blunt hammer,
 # by pausing for a period of time and then rerunning portions of the script.

 # Verify script ran correctly

 # First get number of members in each group

 $nMU = (Get-AzureADGroupMember -ObjectId $MobileUsersGUID).count
 $nMa = (Get-AzureADGroupMember -ObjectId $ManagersGUID).count
 $nRE = (Get-AzureADGroupMember -ObjectId $RegularEmployeesGUID).count

 If ($nMU -lt 9 -or $nMA -lt 4 -or $nRE -lt 5)
 {write-host "Groups not properly populated. Rerunning portion of script." -ForegroundColor Yellow 
    write-host "You may see errors showing that members already exist in a particular group." -ForegroundColor Yellow -BackgroundColor Red
    write-host "The script is using a blunt and extremley unsubtle hammer to try to ensure groups are properly populated." -ForegroundColor Yellow
    write-host "Consequently, these errors are normal and expected in this circumstance." -ForegroundColor Yellow
    write-host "Pausing for 30 seconds before proceeding..." -ForegroundColor Cyan
    sleep -Seconds 30
 }

 
  

 If ($nMU -lt 9)
  {$NewUserIDs=(Get-AzureADUser | where {$_.department -ne $null}).ObjectID
    Foreach ($ID in $NewUserIDs) {
    Add-AzureADGroupMember -ObjectId $MobileUsersGUID -RefObjectId $ID
    }
    }

If ($nMa -lt 4)
  {$ManagerIDs=(Get-AzureADUser | where {$_.JobTitle -eq "Manager"}).ObjectID
    Foreach ($ID in $ManagerIDs) {
    Add-AzureADGroupMember -ObjectId $ManagersGUID -RefObjectId $ID
    }
    }

 If ($nRe -lt 5)
  {$StaffIDs=(Get-AzureADUser | where {$_.JobTitle -ne "Manager" -and $_.department -ne $null}).ObjectID
    Foreach ($ID in $StaffIDs) {
    Add-AzureADGroupMember -ObjectId $RegularEmployeesGUID -RefObjectId $ID
    }
    }

    

 $nMU = (Get-AzureADGroupMember -ObjectId $MobileUsersGUID).count
 $nMa = (Get-AzureADGroupMember -ObjectId $ManagersGUID).count
 $nRE = (Get-AzureADGroupMember -ObjectId $RegularEmployeesGUID).count

 If ($nMU -lt 9 -or $nMA -lt 4 -or $nRE -lt 5)
 {write-host "Groups still not not properly populated!! Please rerun entire script or ask for assistance!" -ForegroundColor red -BackgroundColor Yellow
 }
 Else
  {Write-host "Users and groups created successfully!" -ForegroundColor Green
  write-host "" 
  }