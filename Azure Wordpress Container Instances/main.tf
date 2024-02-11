//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}

resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

resource "azurerm_public_ip" "appGatewayPublicIP" {
  name                = "appGatewayPublicIP"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_application_gateway" "appGateway" {
  name                = "appGateway"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "gatewayIPConfiguration"
    subnet_id = azurerm_subnet.applicationGatewaySubnet.id
  }

  frontend_port {
    name = "gatewayFrontendPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "gatewayFrontEndName"
    public_ip_address_id = azurerm_public_ip.appGatewayPublicIP.id
  }

  backend_address_pool {
    name = "gatewayBackendAddressPool"
    ip_addresses = [azurerm_container_group.containerGroup.ip_address]
  }

  backend_http_settings {
    name                  = "gatewayHTTPSetting"
    cookie_based_affinity = "Disabled"
    path                  = ""
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "gatewayHTTPListener"
    frontend_ip_configuration_name = "gatewayFrontEndName"
    frontend_port_name             = "gatewayFrontendPort"
    protocol                       = "Http"
  }

    request_routing_rule {
    name                       = "gatewayRoutingRule"
    rule_type                  = "Basic"
    http_listener_name         = "gatewayHTTPListener"
    backend_address_pool_name  = "gatewayBackendAddressPool"
    backend_http_settings_name = "gatewayHTTPSetting"
    priority = 1
  }
  

waf_configuration {
  enabled = true
  firewall_mode            = "Detection"
    rule_set_version         = "3.1"
    file_upload_limit_mb     = 100
    max_request_body_size_kb = 128  
}
}
locals {
 mySqlServerName = "mysqlserver${random_string.random.result}"
}


resource "azurerm_private_dns_zone" "fileDnsPrivateZone" {
  name                = "file.core.windows.net"
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_private_dns_zone" "fileDnsPrivateZone" {
  name                = "blob.core.windows.net"
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "fileDnsZoneLink" {
  name = "filedDnszonelink"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
  private_dns_zone_name = azurerm_private_dns_zone.fileDnsPrivateZone.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "fileDnsZoneLink" {
  name = "blobDnszonelink"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_id = azurerm_virtual_network.wordpressVnet.id
  private_dns_zone_name = azurerm_private_dns_zone.blobDnsPrivateZone.name
}

resource "azurerm_private_dns_a_record" "storageDNS" {
  name                = azurerm_storage_account.storageAccount.name
  zone_name           = azurerm_private_dns_zone.fileDnsPrivateZone.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ttl                 = 300
  records             = ["10.0.5.10"]
  depends_on = [ azurerm_private_endpoint.storageAccountEndpoint ]
}

resource "azurerm_private_dns_a_record" "storageDNS" {
  name                = azurerm_storage_account.storageAccount.name
  zone_name           = azurerm_private_dns_zone.blobDnsPrivateZone.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ttl                 = 300
  records             = ["10.0.5.10"]
  depends_on = [ azurerm_private_endpoint.storageAccountEndpoint ]
}

resource "azurerm_container_group" "containerGroup" {
  name                = "containerGroup"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ip_address_type     = "Private"
  os_type             = "Linux"

  diagnostics {
    log_analytics {
      workspace_id = azurerm_log_analytics_workspace.logAnalytics.workspace_id
      workspace_key = azurerm_log_analytics_workspace.logAnalytics.primary_shared_key
    }
  }

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
      port     = 443
      protocol = "TCP"
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
    azurerm_storage_share.storageShareFile,
    azurerm_private_endpoint.storageAccountEndpoint,
    azurerm_log_analytics_workspace.logAnalytics
  ]
}

resource "azurerm_storage_account" "storageAccount" {
  name                     = "storage${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.resourceGroup.name
  location                 = azurerm_resource_group.resourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled = true
}

resource "azurerm_private_endpoint" "storageAccountEndpoint" {
  name                = "storageAccountEndpoint"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  subnet_id           = azurerm_subnet.storageAccountSubnet.id
  ip_configuration {
    name = "StorageAccountIP"
    private_ip_address = "10.0.5.10"
    subresource_name = "file"
    member_name = "file"
  }

  private_service_connection {
    name                           = "storageEndpoint"
    private_connection_resource_id = azurerm_storage_account.storageAccount.id
    is_manual_connection           = false
    subresource_names = ["file"]
  }
  depends_on = [ azurerm_storage_share.storageShareFile ]
}

resource "azurerm_storage_account_network_rules" "storageNetworkRule" {
  storage_account_id = azurerm_storage_account.storageAccount.id
  default_action             = "Deny"
  depends_on = [ azurerm_redis_cache.redisCacheMysql,
  azurerm_storage_share.storageShareFile,
  null_resource.parameterChange,
  null_resource.storageUploadConfig
  //null_resource.storageUpload
  ]
}


resource "azurerm_storage_share" "storageShareFile" {
  name                 = "wordpress"
  storage_account_name = azurerm_storage_account.storageAccount.name
  quota                = 50

  depends_on = [ azurerm_storage_account.storageAccount ]
}

resource "azurerm_storage_container" "acrBlobContainer" {
  name                  = "acrBlobContainer"
  storage_account_name  = azurerm_storage_account.storageAccount.name
  container_access_type = "private"
  depends_on = [ azurerm_storage_account.storageAccount ]
}


//networking resources

resource "azurerm_network_security_group" "containerSubnetNsg" {
  name                = "containerSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  depends_on = [ azurerm_subnet.subnetContainer ]
  security_rule {
    name                       = "MySQLInbound"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = azurerm_container_group.containerGroup.ip_address
  }
  security_rule {
    name                       = "MySQLOutbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.2.0/24"
  }
  security_rule {
    name                       = "RedisInbound"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = azurerm_container_group.containerGroup.ip_address
  }
  security_rule {
    name                       = "RedisOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.4.0/24"
  }
  security_rule {
    name                       = "StorageInbound"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "445"
    destination_port_range     = "445"
    source_address_prefix      = "10.0.5.0/24"
    destination_address_prefix = azurerm_container_group.containerGroup.ip_address
  }

  security_rule {
    name                       = "StorageOutbound"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "445"
    destination_port_range     = "445"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.5.0/24"
  }
  security_rule {
    name                       = "ApplicationGatewayOutbound"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "445"
    destination_port_range     = "445"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.3.0/24"
  }
}



resource "azurerm_network_security_group" "sqlSubnetNsg" {
  name                = "sqlSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  depends_on = [ azurerm_subnet.sqlSubnet ]
  security_rule {
    name                       = "ContainerOutbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = azurerm_container_group.containerGroup.ip_address
  }
  security_rule {
    name                       = "ContainerInbound"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.2.0/24"
  }
  security_rule {
    name                       = "RedisInbound"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
  security_rule {
    name                       = "RedisOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.4.0/24"
  }
  security_rule {
    name                       = "StorageInbound"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "445"
    destination_port_range     = "445"
    source_address_prefix      = "10.0.5.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }

  security_rule {
    name                       = "StorageOutbound"
    priority                   = 104
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "445"
    destination_port_range     = "445"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.5.0/24"
  }
}

resource "azurerm_network_security_group" "RedisSubnetNsg" {
  name                = "containerSubnetNsg"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  depends_on = [ azurerm_subnet.redisCacheSubnet ]
  security_rule {
    name                       = "MySQLInbound"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.2.0/24"
    destination_address_prefix = "10.0.4.0/24"
  }
  security_rule {
    name                       = "MySQLOutbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "3306"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = "10.0.2.0/24"
  }
  security_rule {
    name                       = "RedisOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = "10.0.4.0/24"
    destination_address_prefix = azurerm_container_group.containerGroup.ip_address
  }
  security_rule {
    name                       = "RedisInbound"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "6379"
    destination_port_range     = "6379"
    source_address_prefix      = azurerm_container_group.containerGroup.ip_address
    destination_address_prefix = "10.0.4.0/24"
  }
}

resource "azurerm_subnet_network_security_group_association" "ContainernsgAssociation" {
  subnet_id                 = azurerm_subnet.subnetContainer.id
  network_security_group_id = azurerm_network_security_group.containerSubnetNsg.id
  depends_on = [ azurerm_network_security_group.containerSubnetNsg ]
}

resource "azurerm_subnet_network_security_group_association" "sqlNsgAssociation" {
  subnet_id                 = azurerm_subnet.sqlSubnet.id
  network_security_group_id = azurerm_network_security_group.sqlSubnetNsg.id
  depends_on = [ azurerm_network_security_group.sqlSubnetNsg ]
}

resource "azurerm_subnet_network_security_group_association" "RedisNsgAssociation" {
  subnet_id                 = azurerm_subnet.redisCacheSubnet.id
  network_security_group_id = azurerm_network_security_group.RedisSubnetNsg.id
  depends_on = [ azurerm_network_security_group.RedisSubnetNsg ]
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

resource "azurerm_subnet" "applicationGatewaySubnet" {
  name = "applicationGatewaySubnet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_subnet" "redisCacheSubnet" {
  name = "redisCacheSubnet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.4.0/24"]
}

resource "azurerm_subnet" "storageAccountSubnet" {
  name = "storageAccountSubnet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.5.0/24"]
  service_endpoints = [ "Microsoft.storage" ]
}

resource "azurerm_subnet" "devopsAgentSubnet" {
  name = "devopsAgentSubnet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.wordpressVnet.name
  address_prefixes     = ["10.0.6.0/24"]

    delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
    }
  }
}



//SQL resources
resource "azurerm_mysql_flexible_server" "mySqlServer" {
  name                   = local.mySqlServerName
  resource_group_name    = azurerm_resource_group.resourceGroup.name
  location               = azurerm_resource_group.resourceGroup.location
  administrator_login    = "mysqladmin"
  administrator_password = azurerm_key_vault_secret.vaultSecret.value
  sku_name               = "GP_Standard_D2ds_v4"
  delegated_subnet_id    = azurerm_subnet.sqlSubnet.id
  backup_retention_days = 20
  high_availability {
    mode = "SameZone"
}

 depends_on = [azurerm_key_vault.keyVault]
}

resource "null_resource" "parameterChange" {
  provisioner "local-exec" {
command = "az mysql flexible-server parameter set --resource-group ${azurerm_resource_group.resourceGroup.name} --server-name ${azurerm_mysql_flexible_server.mySqlServer.name} --name require_secure_transport --value OFF"
  }
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

resource "azurerm_redis_cache" "redisCacheMysql" {
  name                = "redisCacheMysql"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  capacity            = 1
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = true
  public_network_access_enabled = "false"

  redis_configuration {
    aof_backup_enabled = false
 aof_storage_connection_string_0 = "DefaultEndpointsProtocol=https;BlobEndpoint=${azurerm_storage_account.storageAccount.primary_blob_endpoint};AccountName=${azurerm_storage_account.storageAccount.name};AccountKey=${azurerm_storage_account.storageAccount.primary_access_key}"
  }
}

locals {
  storageDestination = "https://${azurerm_storage_account.storageAccount.name}.file.core.windows.net/wordpress"
}


resource "null_resource" "storageUpload" {
  provisioner "local-exec" {
command = "az storage file upload-batch --destination ${local.storageDestination} --destination-path /wp-content/plugins --source ./redisCachePlugin --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key}"
  }
}

resource "null_resource" "storageDeleteConfig" {
  provisioner "local-exec" {
command = "az storage file delete --path ./wp-config.php --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key} --share-name wordpress"
  }
  depends_on = [ azurerm_storage_share.storageShareFile,
  azurerm_container_group.containerGroup
   ]
}

resource "null_resource" "storageUploadConfig" {
  provisioner "local-exec" {
command = "az storage file upload --source ./wp-config.php --account-name ${azurerm_storage_account.storageAccount.name} --account-key ${azurerm_storage_account.storageAccount.primary_access_key} --share-name wordpress"
  }
  depends_on = [ null_resource.storageDeleteConfig ]
}

resource "azurerm_private_endpoint" "redisEndpoint" {
  name                = "redisEndpoint"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  subnet_id           = azurerm_subnet.redisCacheSubnet.id

  private_service_connection {
    name                           = "redisPrivateServiceConnection"
    private_connection_resource_id = azurerm_redis_cache.redisCacheMysql.id
    is_manual_connection           = false
  subresource_names = ["redisCache"]
  }
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

resource "azurerm_key_vault_secret" "storageAccessKey" {
  name         = "storageAccessKey"
  value        = azurerm_storage_account.storageAccount.primary_access_key
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault,
  var.sqlPassword
  ]
}

resource "azurerm_key_vault_secret" "storageAccountName" {
  name         = "storageAccountName"
  value        = azurerm_storage_account.storageAccount.name
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault,
  var.sqlPassword
  ]
}


resource "azurerm_log_analytics_workspace" "logAnalytics" {
  name                = "logAnalytics"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_registry" "containerAcrWordpress" {
  name                = "Acr-${random_string.random.result}"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "Standard"
  admin_enabled       = yes
}

resource "azurerm_public_ip" "devopsAgentPublicIP" {
  name                = "devopsAgentPublicIP"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  allocation_method   = "Static"
}

resource "azurerm_nat_gateway" "devopsAgentNatGateway" {
  name                    = "devopsAgentNatGateway"
  location                = azurerm_resource_group.resourceGroup.location
  resource_group_name     = azurerm_resource_group.resourceGroup.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  depends_on = [ azurerm_subnet.devopsAgentSubnet ]
}

resource "azurerm_nat_gateway_public_ip_association" "devopsAgentPublicIPAssociation" {
  nat_gateway_id       = azurerm_nat_gateway.devopsAgentNatGateway.id
  public_ip_address_id = azurerm_public_ip.devopsAgentPublicIP.id
  depends_on = [ azurerm_nat_gateway.devopsAgentNatGateway,
  azurerm_public_ip.devopsAgentPublicIP ]
}

resource "azurerm_subnet_nat_gateway_association" "example" {
  subnet_id      = azurerm_subnet.devopsAgentSubnet.id
  nat_gateway_id = azurerm_nat_gateway.devopsAgentNatGateway.id
  depends_on = [ azurerm_nat_gateway.devopsAgentNatGateway ]
}

resource "azurerm_container_group" "devopsAgentcontainerGroup" {
  name                = "devopsAgentcontainerGroup"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ip_address_type     = "Private"
  os_type             = "Linux"

  subnet_ids = [azurerm_subnet.devopsAgentSubnet.id]

  container {
    name   = "Agent"
    image  = "${azurerm_container_registry.containerAcrWordpress.name}.azurecr.io/agent-container:v2"
    cpu    = "0.5"
    memory = "0.5"

        ports {
      port     = 80
      protocol = "TCP"
    }

            ports {
      port     = 443
      protocol = "TCP"
    }
  }
  image_registry_credential {
    server = azurerm_container_registry.name
    username = azurerm_container_registry.containerAcrWordpress.admin_username
    password = azurerm_container_registry.containerAcrWordpress.admin_password
  }
}

resource "azurerm_container_registry_task" "registryTask" {
  name                  = "example-task"
  container_registry_id = azurerm_container_registry.containerAcrWordpress.id
  platform {
    os = "Linux"
  }
  docker_step {
    dockerfile_path      = "Dockerfile"
    context_path         = "https://${azurerm_storage_account.storageAccount.name}.blob.core.windows.net/acrBlobContainer"
    context_access_token = azurerm_storage_account.storageAccount.primary_access_key
    image_names          = ["${azurerm_container_registry.containerAcrWordpress.name}.azurecr.io/agent-container:v3"]
    push_enabled = yes
  }
}