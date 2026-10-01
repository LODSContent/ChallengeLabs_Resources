# Create 2 Virtual Machines under a Load balancer and configures Load Balancing rules for the VMs

**NOTE:** This template is a copy of the Microsoft [201-2-vms-loadbalancer-lbrules](https://github.com/Azure/azure-quickstart-templates/tree/master/201-2-vms-loadbalancer-lbrules) Azure Quick Start template and is provided here only to support labs on the LODS platform.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FLODSContent%2FChallengeLabs_ArmResources%2Fmaster%2FARMTemplates%2F201-2-vms-loadbalancer-lbrules%2Fazuredeploy.json)  [![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F201-2-vms-loadbalancer-lbrules%2Fazuredeploy.json)

This template allows you to create 2 Virtual Machines under a Load balancer and configure a load balancing rule on Port 80. This template also deploys a Storage Account, Virtual Network, Public IP address, Availability Set and Network Interfaces.

In this template, we use the resource loops capability to create the network interfaces and virtual machines

