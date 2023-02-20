# Site to Site VPN
Template objective is creating a site to site vpn with Terraform

## Resources created in Template

vnet: Azure virtual network that the vpn will connect to

public IP: Azure IP address that the local network gateway will connect to

virtual network gateway: Azure gateway that the remote network (other side of the vpn) will connect to

Local Network Gateway: Defining remote gateway address space

Virtual Network Gateway Connection: connecting Virtual Network Gateway to Local Network Gateway

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
