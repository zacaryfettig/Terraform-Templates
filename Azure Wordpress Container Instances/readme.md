# Azure Wordpress Container Architecture and Deployment
Hosts a highly available Wordpress website using Container instances and Azure MySQL Database. Reference instructions for deployment at https://www.zacaryfettig.com/portfolio/azure-wordpress

## Resources created in Template
* Application Gateway: Layer 7 load balancer with Web Application Firewall. Requests come in through the gateway and privately connects to container instances.
* Container Instances: Hosts the WordPress Application using the Official WordPress Docker Image.
* Azure Cache for Redis: Caches MySQL Database for faster database reads by the WordPress Application.
* Azure Database MySQL Flexible Server: Highly Available MySQL Database serving as the database server for the WordPress Instance.
* Azure Storage Account: Allows access for editing container instances files through Azure File Share. Also stores AOF backups for Redis Cache which will allow for faster spin up times when the cache/database is offline for a while.
* Azure Private DNS Zone: All resources are accessed via private endpoint when possible with Public Access turned off. The DNS zone allows vnet connected resources to reach the Storage Account through DNS Name pointing the resource to Private IP.
* Log Analytics Workspace: Retrieve logs from resources.
* Azure Keyvault: Keeps resource secrets/passwords in Vault that can be securely accessed/used.
* Azure Devops Pipline: CI/CD pipeline gets updated theme files/plug ins/data from GitHub and adds them to the WordPress Container.
* Self Hosted Azure Devops Container Instance: allows Azure Devops private network connectivity to Azure Resources. Runs the pipeline from the container.
* Container Registry: Hosts images for container deployment. In this case the image for Self Hosted Devops Agent.
