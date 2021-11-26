
# This script can be used to deploy a Bastion Host into an existing virtual network. 
#
# The script gets and creates some values that are necessary to pass into the ARM template as parameters.
# It then uses those values to deploy the ARM Template for the Bastion Host.
#
# To use this script, please replace the value for the $RGName variable with a valid resource group name.
# Before running the script, you need to ensure that you have created a virtual network with at least one subnet.
#
# NOTE: This script assumes that the resource group contains only one virtual network. If you have more than one virtual network,
# you will need to modify the get-azvirtualnetwork command to include the name of the virtual network that you want to 
# install the Bastion Host into. 

$RGName = <Resource Group Name>

#Get Resource Group location

$location = (Get-AzResourceGroup -Name $RGName).Location

#Get the virtual network in the resource group. Script assumes only one vnet. 

$Vnet= get-azvirtualnetwork -ResourceGroupName $RGName # -Name <vnetName>

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

# Deploy the ARM template

New-AzResourceGroupDeployment -ResourceGroupName $RGName -TemplateParameterObject $params -TemplateUri https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ARMTemplates/createBastionHost.json


