
$RGName = 'az140-11-RG'

#Get Resource Group location

$location = (Get-AzResourceGroup -Name $RGName).Location

#Get the virtual network in the resource group. Script assumes only one vnet. 

$Vnet= get-azvirtualnetwork -ResourceGroupName $RGName

# Get the VNet name and store it in a variable for use with ARM template deployment

$existingVNETName = $vnet.Name

# Get first subnet in Vnet subnet arrary

$subnet = $vnet.subnets[0]

# Get the Address Prefix for the subnet

$AddressPrefix = $subnet.AddressPrefix

# Create an array of the values in the IP address

$iparray=$AddressPrefix.split(".")

# Update the 3rd octet in the IP address prefix with a new value representing a network subnet that is unlikely to be in use.

$iparray.Item(2)="251"

# Recombine the array and put it into a variable for use with ARM template deployment

$subnetAddressPrefix = $iparray -join "."

#Create a hashtable that contains the parameters for the ARM template deployment

$params = @{
    resourceGroup = $RGName
    existingVNETName = $existingVNETName
    subnetAddressPrefix = $subnetAddressPrefix
    location = $location
    publicIPaddressName = "bastion-pub-IP"
}

New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $params -TemplateUri 


