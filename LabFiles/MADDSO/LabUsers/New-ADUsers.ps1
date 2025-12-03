# Store the data from NewADUsers.csv in the $ADUsers variable
$ADUsers = Import-csv .\LabUsers.csv

$ADDomain = Get-ADDomain

# Loop through each row in the CSV Sheet
foreach ($User in $ADUsers)
{
    # Read data from each field in the row and assign data to a variable
    $Username   = $User.username
	$UserPrincipalName = $User.username + "@" + $ADDomain.DNSRoot
    $email      = $User.email + "@" + $ADDomain.DNSRoot	
    $Password   = $User.password
    $Firstname  = $User.firstname
    $Lastname   = $User.lastname
    $OU         = $User.ou + "," + $ADDomain.DistinguishedName
    $streetaddress = $User.streetaddress
    $city       = $User.city
    $zipcode    = $User.zipcode
    $state      = $User.state
    $country    = $User.country
    $description = $User.description
    $office     = $User.office
    $telephone  = $User.telephone
    $jobtitle   = $User.jobtitle
    $company    = $ADDomain.Name
    $department = $User.department
    $Password   = $User.Password

    # Check if user already exists
    if (Get-ADUser -F {SamAccountName -eq $Username})
    {
        # If user exists, give warning
        Write-Warning "User account $Username already exists."
    }
    else
    {
        # User does not exist so proceed with creation of new user account
        New-ADUser `
            -SamAccountName $Username `
            -UserPrincipalName $UserPrincipalName `
            -Name "$Firstname $Lastname" `
            -GivenName $Firstname `
            -Surname $Lastname `
            -Enabled $True `
            -DisplayName "$Lastname, $Firstname" `
            -Path $OU `
            -City $city `
            -Company $company `
            -State $state `
            -StreetAddress $streetaddress `
            -OfficePhone $telephone `
            -EmailAddress $email `
            -Title $jobtitle `
            -Department $department `
            -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force) -ChangePasswordAtLogon $True
    }
}