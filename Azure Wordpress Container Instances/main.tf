//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}

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







resource "azurerm_container_group" "containerGroup" {
  name                = "containerGroup"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids = [azurerm_subnet.subnetContainer.id]

  container {
    name   = "wordpress"
    image  = "wordpress"
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 443
      protocol = "TCP"
    }

    environment_variables = {
            "WORDPRESS_DB_HOST" = "db"
      "WORDPRESS_DB_USER" = "exampleuser"
      "WORDPRESS_DB_PASSWORD" = "examplepass"
      "WORDPRESS_DB_NAME" = "exampledb"
    }
    volume {
      name = "db"
      mount_path = "/var/lib/mysql"
      
    }
  }
  
        depends_on = [
    azurerm_virtual_network.wordpressVnet
  ]
}


resource "azurerm_container_registry" "wordpressAcr" {
  name                = "wordpressAcr"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "Standard"
  admin_enabled       = true
}

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

resource "azurerm_virtual_network" "wordpressVnet" {
  name                = "vnet"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnetContainer" {
  name = "subnetContainer"
  resource_group_name = azurerm_resource_group.resourceGroup.name
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
  resource_group_name  = azurerm_resource_group.resourceGroup.name
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
resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

//SQL resources
resource "azurerm_mysql_flexible_server" "mySqlServer" {
  name                   = "mysqlserver${random_string.random.result}"
  resource_group_name    = azurerm_resource_group.resourceGroup.name
  location               = azurerm_resource_group.resourceGroup.location
  administrator_login    = "mysqladmin"
  administrator_password = azurerm_key_vault_secret.vaultSecret.value
  sku_name               = "B_Standard_B1s"
   delegated_subnet_id    = azurerm_subnet.sqlSubnet.id
        depends_on = [
    azurerm_key_vault.keyVault,
    var.sqlPassword,
  ]
}

resource "azurerm_mysql_flexible_database" "mySqlDB" {
  name                = "mySqlDB"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  server_name         = azurerm_mysql_flexible_server.mySqlServer.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
      depends_on = [
    azurerm_mysql_flexible_server.mySqlServer
  ]
}

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

//keyvautl resources
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVault-${random_string.random.result}"
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
*/