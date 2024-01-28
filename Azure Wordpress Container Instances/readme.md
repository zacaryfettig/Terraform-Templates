# Deploying infrastructure for a web app with SQL based Database using Terraform
Template objective is hosting a .net web app with SQL database while maintaining connection security from the SQL Database to the web app.

## Resources created in Template
* Application Gateway: Layer 7 load balancer with WAF. Privatly connects Azure Container Instances to the internet.

* Container Instances: Hosting Wordpress on a container using the Wordpress Docker Image.

* Azure SQL Database Server: Creation of Azure Databases server resource

* Azure SQL Database: Database storing website database

* Networking VNet: Connect SQL Service to App over private VNet

* Private Endpoint: Connecting SQL privatly over vnet

* App Service Vnet Integration: Connect App Service privatly to VNet

* Key Vault: Store SQL Database Admin password securly in Key Vault. secret is created at template runtime.

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

