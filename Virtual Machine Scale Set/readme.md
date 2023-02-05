# Virtual Machine Scale Set
Template objective is hosting a server application that has the ability to size up/down depending on the amount of users

## Resources created in Template

* VM Scale set: provide the ability to scale up/down and load balance between instances

* VNet: network communication between resources

* Load Balancer: balacing traffic between vm's

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
