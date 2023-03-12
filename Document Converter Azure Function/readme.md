# Word to PDF converter Azure Function - Build Out In Progress
Template objective is to create Function App Resources through Terraform and deploy a PDF converter .Net core Application. Github actions used to deploy Infanstructure and Application through the touch of a button in Github.

## Resources created in Template
* App Service: Hosting Web App using App Service

* Azure SQL Database Server: Creation of Azure Databases server resource

* Azure SQL Database: Database storing website database

* Networking VNet: Connect SQL Service to App over private VNet

* Private Endpoint: Connecting SQL privatly over vnet

* App Service Vnet Integration: Connect App Service privatly to VNet

* Key Vault: Store SQL Database Admin password securly in Key Vault. secret is created at template runtime.
