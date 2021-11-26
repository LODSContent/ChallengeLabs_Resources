# Create a Bastion Host

This template will deploy a bastion host into an existing virtual network. 

A bastion host provides secure RDP or SSH access to Azure Virtual Machines (VMs). With a bastion host,
you can securely gain remote access to Azure VMs through the Azure Portal. Direct RDP or SSH access to the Azure VMs 
from Internet hosts is not permitted when you configure a bastion host in the same virtual network as the Azure VMs.

Deploy the bastion host into a virtual network that has Azure VMs you want to protect from 
brute-force and dictionary password attacks and unauthorized access. 

**NOTE:** This template requires an existing resource group and virtual network. 

To deploy the bastion host, click the button below.

[![Deploy To Azure](https://raw.githubusercontent.com/az140mp/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Faz140mp%2Fazure-quickstart-templates%2Fmaster%2Fapplication-workloads%2Factive-directory%2Factive-directory-new-domain%2Fazuredeploy.json)
