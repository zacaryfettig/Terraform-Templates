# Creation of a Container Group in Azure Container Instances
Template objective is to create a container in Azure container instances 

## Resources created in Template
* Container Group: Group for containers specifiying common OS type and IP address data 

* Container: Holds application code and files on are shared OS

* Virtual Network: internal network/network connection

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
