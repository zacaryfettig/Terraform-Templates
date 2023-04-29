# Connecting Sites and Resouces togeather using Azure Virtual Wan
Template objective is to create a resource that easily manages

## Resources created in Template
* Virtual Wan: Connects Express route, site to site & point to site vpn's, virtual networks, and other resources in Azure while using one managment interface.

* Virtual Hub: Central point of connectivity per a region.

* VPN Gateway: Connects on-prem resources to Azure

* VPN Site: Remote Gateway config information

* Azure VNETS: Azure based subnet networks

* Virtual Hub Connection: Remote Gateway config information

## Resource Deployment

```
terraform init
```

```
terraform plan
```

```
terraform apply
```

#### Deployment Terms
terraform init: Run terraform init to initialize the Terraform deployment. This command downloads the Azure modules required to manage your Azure resources.

terraform plan: creates an execution plan, but doesn't execute it. Instead, it determines what actions are necessary to create the configuration specified in your configuration files.

terraform apply: apply the execution plan to your cloud infrastructure.

