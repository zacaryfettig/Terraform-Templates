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

  tags = {
    environment = "staging"
  }
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
  admin_password      = "P@55w0rd1234!"
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-Server"
    version   = "latest"
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