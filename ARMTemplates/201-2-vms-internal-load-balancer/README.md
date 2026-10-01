# Create 2 Virtual Machines under an Internal Load balancer and Configure Load Balancing rules for the VMs

**NOTE:** This template is a copy of the Microsoft [201-2vms-internal-load-balancer](https://github.com/Azure/azure-quickstart-templates/tree/master/quickstarts/microsoft.compute/2-vms-internal-load-balancer) Azure Quick Start template and is provided here only to support labs on the LODS platform.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FLODSContent%2FChallengeLabs_ArmResources%2Fmaster%2FARMTemplates%2F201-2-vms-internal-load-balancer%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FLODSContent%2FChallengeLabs_ArmResources%2Fmaster%2FARMTemplates%2F201-2-vms-internal-load-balancer%2Fazuredeploy.json)

This template allows you to create 2 Virtual Machines under an Internal Load balancer. To learn more about how to deploy the template, see the [quickstart](https://docs.microsoft.com/azure/load-balancer/quickstart-load-balancer-standard-internal-template) article.

This template also deploys a Storage Account, Virtual Network, Availability Set and Network Interfaces.

The Azure Load Balancer is assigned a static IP in the Virtual Network and is configured to load balance on Port 80.
