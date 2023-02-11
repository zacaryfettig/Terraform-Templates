resource "azurerm_resource_group" "resourceGroup" {
  name     = "resouceGroup"
  location = "westus3"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_prefixes     = ["10.0.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "publicIP" {
  name                = "publicIP"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  allocation_method   = "Static"
  domain_name_label   = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_lb" "loadbalancer" {
  name                = "loadbalancer"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.publicIP.id
  }
}

resource "azurerm_lb_backend_address_pool" "lbbackEndPool" {
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_probe" "lbProbe" {
  loadbalancer_id     = azurerm_lb.loadbalancer.id
  name                = "http-probe"
  protocol            = "Http"
  request_path        = "/health"
  port                = 8080
}

resource "azurerm_windows_virtual_machine_scale_set" "scaleSet" {
  name                = "scaleSet"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku                 = "Standard_F2"
  instances           = 1
  admin_password      = var.vmUsername
  admin_username      = var.vmPassword

  source_image_reference {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
    version   = var.version
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "ipConfig"
      primary   = true
      subnet_id = azurerm_subnet.subnet.id
    }
  }
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
  name         = "vmPassword"
  value        = var.vmPassword
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault
  ]
}