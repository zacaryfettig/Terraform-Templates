//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}

//dns resources & private endpoint
resource "azurerm_private_dns_zone" "dnsPrivateZone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name = "dnszonelink"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_id = azurerm_virtual_network.vnet.id
  private_dns_zone_name = azurerm_private_dns_zone.dnsPrivateZone.name
}

resource "azurerm_private_endpoint" "privateEndpoint" {
  name                = "privateEndpoint"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  subnet_id           = azurerm_subnet.sqlSubnet.id

  private_dns_zone_group {
    name = "privateDnsZoneGroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnsPrivateZone.id]
  }

  private_service_connection {
    name = "privateEndpointConnection"
    private_connection_resource_id = azurerm_mssql_database.sqlDB.id
    is_manual_connection = false
  }
}

//networking resources
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "delegationSubnet" {
  name                 = "delagationSubnet"
  resource_group_name  = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/serverFarms"
    }
  }
}

resource "azurerm_subnet" "sqlSubnet" {
  name                 = "sqlSubnet"
  resource_group_name  = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}


//App Service resources
resource "azurerm_service_plan" "appServicePlan" {
  name                = "${azurerm_resource_group.resourceGroup.name}-appPlan"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku_name            = "P1v2"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "appService" {
  name                = "${azurerm_resource_group.resourceGroup.name}-appService"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  service_plan_id     = azurerm_service_plan.appServicePlan.id

site_config {
always_on = true
  }
}

//SQL resources
resource "azurerm_mssql_server" "sqlServer" {
  name                         = "sqlserver-${azurerm_resource_group.resourceGroup.id}"
  resource_group_name          = azurerm_resource_group.resourceGroup.name
  location                     = azurerm_resource_group.resourceGroup.location
  version                      = "12.0"
  administrator_login          = sqlUsername
  administrator_login_password = azurerm_key_vault_secret.vaultSecret.value
  public_network_access_enabled = false
  
  depends_on = [
    azurerm_key_vault.keyVault,
    var.sqlUsername,
    var.sqlPassword,

  ]
}

resource "azurerm_mssql_database" "sqlDB" {
  name           = "sqlDB"
  server_id      = azurerm_mssql_server.sqlServer.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  license_type   = "LicenseIncluded"
  max_size_gb    = 4
  read_scale     = true
  sku_name       = "S0"
  zone_redundant = true

  depends_on = [
    azurerm_mssql_server.sqlServer,
  ]
}

resource "azurerm_mssql_firewall_rule" "example" {
  name             = "FirewallRule1"
  server_id        = azurerm_mssql_server.sqlServer.id
  start_ip_address = "10.0.2.1"
  end_ip_address   = "10.0.2.254"

  depends_on = [
    azurerm_mssql_server.sqlServer,
    azurerm_mssql_database,
  ]
}

//keyvautl resources
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVaul1239"
  location                    = azurerm_resource_group.resourceGroup.location
  resource_group_name         = azurerm_resource_group.resourceGroup.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
    ]

  }
}

resource "azurerm_key_vault_secret" "vaultSecret" {
  name         = "sqlPassword"
  value        = var.sqlPassword
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault
  ]
}