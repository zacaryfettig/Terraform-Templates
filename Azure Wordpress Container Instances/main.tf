/*
//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}
*/

resource "random_id" "front_door_endpoint_name" {
  byte_length = 8
}



locals {
  frontDoorEndpointName     = "afd-${lower(random_id.front_door_endpoint_name.hex)}"
}

resource "azurerm_cdn_frontdoor_profile" "frontDoorProfile" {
  name                = "frontDoorProfile"
  resource_group_name = "rg1"
  sku_name            = "Premium_AzureFrontDoor"
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

resource "azurerm_cdn_frontdoor_route" "frontdoorRouteDefault" {
  name                          = "frontdoorRouteDefault"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.my_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.westusServiceOrigin.id]
  enabled                       = true

  forwarding_protocol    = "MatchRequest"
  https_redirect_enabled = false
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  link_to_default_domain          = true

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}


resource "azurerm_cdn_frontdoor_origin" "westusServiceOrigin" {
  name                          = "westusServiceOrigin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontDoorOriginGroup1.id

  enabled                        = true
  host_name                      = azurerm_container_group.containerGroup.ip_address
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_container_group.containerGroup.ip_address
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
  private_link {
    location = "westus"
    private_link_target_id = azurerm_container_group.containerGroup.id
  }
}

/*
resource "azurerm_private_link_service" "frontDoorPrivateLinkService" {
  name                = "frontDoorPrivateLinkService"
  resource_group_name = "rg1"
  location            = "westus"

  auto_approval_subscription_ids              = ["00000000-0000-0000-0000-000000000000"]
  visibility_subscription_ids                 = ["00000000-0000-0000-0000-000000000000"]
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.example.frontend_ip_configuration.0.id]

  nat_ip_configuration {
    name                       = "primary"
    private_ip_address         = "10.0.1.5"
    private_ip_address_version = "IPv4"
    subnet_id                  = azurerm_subnet.subnetContainer.id
    primary                    = true
  }
}
*/



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



resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}
locals {
 mySqlServerName = "mysqlserver${random_string.random.result}"
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
  ip_address_type     = "Private"
  os_type             = "Linux"
  subnet_ids = [azurerm_subnet.subnetContainer.id]

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


    environment_variables = {
      "WORDPRESS_DB_HOST" = local.mySqlServerName
      "WORDPRESS_DB_USER" = "mysqladmin"
      "WORDPRESS_DB_PASSWORD" = var.sqlPassword
      "WORDPRESS_DB_NAME" = "mysqldb"
    }


    volume {
      name = "wordpress"
      storage_account_name = azurerm_storage_account.storageAccount.name
      mount_path = "/var/www/html"
      share_name = "wordpress"
      storage_account_key = azurerm_storage_account.storageAccount.primary_access_key

    }
  }
  
        depends_on = [
          /*
    azurerm_virtual_network.wordpressVnet,
    */
    azurerm_storage_share_file.storageShareFile
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

resource "azurerm_storage_account" "storageAccount" {
  name                     = "storage${random_string.random.result}"
  resource_group_name      = "rg1"
  location                 = "westus"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "wordpress" {
  name                 = "wordpress"
  storage_account_name = azurerm_storage_account.storageAccount.name
  quota                = 500
  depends_on = [ azurerm_storage_account.storageAccount ]
}

resource "azurerm_storage_share_file" "storageShareFile" {
  name             = "wp-config-docker.php"
  storage_share_id = azurerm_storage_share.wordpress.id
  source           = "wp-config-docker.php"
  depends_on = [ azurerm_storage_share.wordpress ]
}

resource "azurerm_storage_share_file" "storageShareFile2" {
  name             = "wp-config-sample.php"
  storage_share_id = azurerm_storage_share.wordpress.id
  source           = "wp-config-sample.php"
  depends_on = [ azurerm_storage_share.wordpress ]
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



//SQL resources
resource "azurerm_mysql_flexible_server" "mySqlServer" {
  name                   = local.mySqlServerName
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
   // var.sqlPassword,
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
