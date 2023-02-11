resource "azurerm_resource_group" "resourceGroup" {
    name = var.resourceGroup
    location = var.location
}

resource "azurerm_virtual_wan" "virtualWan" {
  name                = "example-virtualwan"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_virtual_hub" "virtualhub" {
  name                = "example-virtualhub"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  virtual_wan_id      = azurerm_virtual_wan.example.id
  address_prefix      = "10.0.0.0/23"
}

resource "azurerm_virtual_hub_connection" "vnet1Connection" {
  name                      = "example-vhub"
  virtual_hub_id            = azurerm_virtual_hub.virtualhub.id
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
}

resource "azurerm_virtual_network" "vnet1" {
  name = "vnet1"
  location = var.location
  resource_group_name = var.resourceGroup
  address_space = [ "10.1.0.0./16" ]
}

resource "azurerm_subnet" "vnet1_subnet1" {
  name = "vnet1_subnet1"
  location = var.location
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes = [ "10.1.1.0/24" ]
}

resource "azurerm_virtual_network" "vnet2" {
  name = "vnet1"
  location = var.location
  resource_group_name = var.resourceGroup
  address_space = [ "10.1.0.0./16" ]
}

resource "azurerm_subnet" "vnet2_subnet1" {
  name = "vnet2_subnet1"
  location = var.location
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes = [ "10.1.1.0/24" ]
}