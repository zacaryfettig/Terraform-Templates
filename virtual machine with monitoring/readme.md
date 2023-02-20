# Virtual Machine with monitoring metrics
Template objective is hosting Template objective is monitoring for VM usage and sending alerts when usage is high

## Resources created in Template

Virtual Machine

VNet: network communication between resources

Public IP: public IP for virtual machine

nic: vm network interface

action group: email alert action

metric alert: alert based on set resource usage trigger


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
