resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.resoureGroupLocation
}

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

 resource "azurerm_subnet" subnet {
    name           = "subnet"
    resource_group_name = azurerm_resource_group.resourceGroup.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes = ["10.0.1.0/24"]
  }

  resource "azurerm_public_ip" "publicIP" {
    name = "publicIP"
    resource_group_name = azurerm_resource_group.resourceGroup.name
    location = azurerm_resource_group.resourceGroup.location
    allocation_method = "Dynamic"
  }

  resource "azurerm_network_interface" "nic" {
  name                = "nic"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name

  ip_configuration {
    name                          = "ipConfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.publicIP.id
  }
}

resource "random_password" "name" {
  length = 8
}

resource "azurerm_windows_virtual_machine" "azureVM" {
  name                = "${var.resourceGroupName}-vm"
  location              = azurerm_resource_group.resourceGroup.location
  resource_group_name   = azurerm_resource_group.resourceGroup.name
  size                = var.vmSize
  admin_username      = var.vmUsername
  admin_password      = var.vmPassword
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.storageAccountType
  }

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.version
  }
}

resource "azurerm_monitor_action_group" "emailAlert" {
  name                = "emailAlert"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  short_name          = "email"

   email_receiver {
    name          = "sendtoadmin"
    email_address = var.email_address
    use_common_alert_schema = true
  }
}



  resource "azurerm_monitor_metric_alert" "cpuThresholdAlert" {
  name                = "cpuThresholdAlert"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  scopes              = [azurerm_windows_virtual_machine.azureVM.id]
  description         = "Action will be triggered when CPU Threshold is greater than 70."

  criteria {
    metric_namespace = var.metric_namespace
    metric_name      = var.metric_name
    aggregation      = var.aggregation
    operator         = var.operator
    threshold        = var.threshold
  }

  action {
    action_group_id = azurerm_monitor_action_group.emailAlert.id

  }
  depends_on = [
    azurerm_monitor_metric_alert.cpuThresholdAlert,
    azurerm_windows_virtual_machine.azureVM
  ]
}

//keyvautl resources
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVault-${var.resourceGroupName.id}"
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