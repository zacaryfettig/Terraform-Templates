/*
//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}
*/
/*
resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}


locals {
  frontDoorEndpointName     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
}

resource "azurerm_cdn_frontdoor_profile" "frontDoorProfile" {
  name                = "frontDoorProfile"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "my_endpoint" {
  name                     = local.frontDoorEndpointName
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontDoorProfile.id
}

resource "azurerm_cdn_frontdoor_origin_group" "frontDoorOriginGroup1" {
  name                     = "frontDoorOrginGroup1"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontDoorProfile.id
  session_affinity_enabled = true

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    path                = "/"
    request_type        = "HEAD"
    protocol            = "Https"
    interval_in_seconds = 100
  }
}

resource "azurerm_cdn_frontdoor_origin" "westusServiceOrigin" {
  name                          = "westusServiceOrigin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id

  enabled                        = true
  host_name                      = "database.com"
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = "database.com"
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

//resource "azurerm_cdn_frontdoor_origin" "ukSouthServiceOrigin" {
//  name                          = "ukSouthServiceOrigin"
//  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id
//
//  enabled                        = true
//  host_name                      = azurerm_windows_web_app.app.default_hostname
//  http_port                      = 80
//  https_port                     = 443
//  origin_host_header             = azurerm_windows_web_app.app.default_hostname
//  priority                       = 1
//  weight                         = 1000
//  certificate_name_check_enabled = true
//}
*/


resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}
/*
resource "azurerm_private_dns_zone" "dnsPrivateZone" {
  name                = "wordpress.mysql.database.azure.com"
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "dnszonelink" {
  name = "dnszonelink"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
  private_dns_zone_name = azurerm_private_dns_zone.dnsPrivateZone.name
}
*/
resource "azurerm_container_group" "containerGroup" {
  name                = "containerGroup"
  location            = "westus"
  resource_group_name = "rg1"
  ip_address_type     = "Public"
  os_type             = "Linux"
  dns_name_label = "wordpress1234"
  /*
  subnet_ids = [azurerm_subnet.subnetContainer.id]

*/
  container {
    name   = "wordpress"
    image  = "wordpress"
    cpu    = "0.5"
    memory = "0.5"

        ports {
      port     = 80
      protocol = "TCP"
    }

            ports {
      port     = 3306
      protocol = "TCP"
    }

/*
    environment_variables = {
      "WORDPRESS_DB_HOST" = azurerm_mysql_flexible_server.mySqlServer.name
      "WORDPRESS_DB_USER" = "mysqladmin"
      "WORDPRESS_DB_PASSWORD" = azurerm_key_vault_secret.vaultSecret.value
      "WORDPRESS_DB_NAME" = "mysqldb"
    }
*/

    volume {
      name = "wordpress"
      storage_account_name = "wordpress897"
      mount_path = "/var/www/html"
      share_name = "wordpress"
      storage_account_key = "8SuabOe+qDTsgw4d9mb+vuFoKTKiNnP/m6bIaaIf0+M04Sh2J3DEO47wvnzxPGKi0pdRkkhJcB4T+AStMirCkg=="
      /*
      storage_account_key = azurerm_storage_account.storage892374234.primary_access_key
      */
    }
  }
  
        depends_on = [
    azurerm_virtual_network.wordpressVnet,
  ]
}

/*
resource "azurerm_container_registry" "wordpressAcr" {
  name                = "wordpressAcr"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "Standard"
  admin_enabled       = true
}


  name                     = "storage${random_string.random.result}"
*/
/*
resource "azurerm_storage_account" "storageAccount" {
  name                     = "storage892374234"
  resource_group_name      = azurerm_resource_group.resourceGroup.name
  location                 = azurerm_resource_group.resourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "wordpress" {
  name                 = "wordpress"
  storage_account_name = azurerm_storage_account.storageAccount.name
  quota                = 500
}
*/
/*
//networking resources
resource "azurerm_network_security_group" "containerSubnetNsg" {
  name                = "containerSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_network_security_group" "sqlSubnetNsg" {
  name                = "sqlSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_subnet_network_security_group_association" "ContainernsgAssociation" {
  subnet_id                 = azurerm_subnet.subnetContainer.id
  network_security_group_id = azurerm_network_security_group.containerSubnetNsg.id
}

resource "azurerm_subnet_network_security_group_association" "sqlNsgAssociation" {
  subnet_id                 = azurerm_subnet.sqlSubnet.id
  network_security_group_id = azurerm_network_security_group.sqlSubnetNsg.id
}
*/
resource "azurerm_virtual_network" "wordpressVnet" {
  name                = "vnet"
  location            = "westus"
  resource_group_name = "rg1"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnetContainer" {
  name = "subnetContainer"
  resource_group_name = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.1.0/24"]

    delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}

resource "azurerm_subnet" "sqlSubnet" {
  name                 = "sqlSubnet"
  resource_group_name  = "rg1"
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.2.0/24"]

      delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
    }
  }
}

//Random generator for SQL and Keyvault names


//SQL resources
resource "azurerm_mysql_flexible_server" "mySqlServer" {
  name                   = "mysqlserver${random_string.random.result}"
  resource_group_name    = "rg1"
  location               = "westus"
  administrator_login    = "mysqladmin"
  administrator_password = azurerm_key_vault_secret.vaultSecret.value
  sku_name               = "B_Standard_B1s"
  /*
   delegated_subnet_id    = azurerm_subnet.sqlSubnet.id
   private_dns_zone_id    = azurerm_private_dns_zone.dnsPrivateZone.id
*/
        depends_on = [
    azurerm_key_vault.keyVault,
    var.sqlPassword,
  ]
}

resource "azurerm_mysql_flexible_database" "mySqlDB" {
  name                = "mySqlDB"
  resource_group_name = "rg1"
  server_name         = azurerm_mysql_flexible_server.mySqlServer.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
      depends_on = [
    azurerm_mysql_flexible_server.mySqlServer
  ]
}
/*
resource "azurerm_mysql_flexible_server_firewall_rule" "mysqlFirewallRule" {
  name                = "mysqlFirewallRule"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  server_name         = azurerm_mysql_flexible_server.mySqlServer.name
  start_ip_address    = "10.0.2.1"
  end_ip_address      = "10.0.2.254"
      depends_on = [
    azurerm_mysql_flexible_server.mySqlServer,
    azurerm_mysql_flexible_database.mySqlDB
  ]
}
*/

//keyvautl resources
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVault-${random_string.random.result}"
  location                    = "westus"
  resource_group_name         = "rg1"
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
      "Set",
    ]
  }
}

resource "azurerm_key_vault_secret" "vaultSecret" {
  name         = "sqlPassword"
  value        = var.sqlPassword
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault,
  var.sqlPassword
  ]
}
