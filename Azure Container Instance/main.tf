//creating Resource Group
resource "azurerm_resource_group" "resourceGroup" {
  name     = var.resourceGroupName
  location = var.location
}

resource "azurerm_container_group" "containerGroup" {
  name                = "resource"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  ip_address_type     = "private"
  dns_name_label      = "aci-label"
  os_type             = "Linux"
  subnet_ids = azurerm_subnet.subnetContainer.id

  container {
    name   = "hello-world"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "2"

    ports {
      port     = 443
      protocol = "TCP"
    }
  }
}

resource "azurerm_virtual_network" "vnetContainer" {
  name                = "vnetContainer"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnetContainer" {
  name = "subnetContainer"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}