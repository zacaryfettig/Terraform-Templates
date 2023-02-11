//create new resource group
resource "azurerm_resource_group" "resourceGroup" {
    name = var.resourceGroup
    location = var.location
}

//create Azure internal virtual network for on prem network to connect to
resource "azurerm_virtual_network" "vnetVPN" {
  name = "vnetVPN"
  location = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space = [ "10.1.0.0./16" ]
}

resource "azurerm_subnet" "vnet_VPN_subnet1" {
  name = "vnet_VPN_subnet1"
  location = azurerm_resource_group.resourceGroup.location
  virtual_network_name = azurerm_resource_group.resourceGroup.name
  address_prefixes = [ "10.1.1.0/24" ]
}

//create public IP for Azure facing connection address
resource "azurerm_public_ip" "publicIP" {
  name                = "publicIP"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  allocation_method   = "Dynamic"
}

//vpn resouces
resource "azurerm_virtual_network_gateway" "virtualNetworkGateway" {
  name = "virtualNetworkGateway"
    location          = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}



resource "azurerm_local_network_gateway" "onSiteGateway" {
  name                = "onSiteGateway"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  gateway_address     = localGatewayAddress
  address_space       = localGatewayAddressSpace
}

resource "azurerm_virtual_network_gateway_connection" "vpnConnection" {
    name                       = "vpnConnection"
    location                   = azurerm_resource_group.resourceGroup.location
    resource_group_name        = azurerm_resource_group.resourceGroup.name
    type                       = "IPsec"
    virtual_network_gateway_id = azurerm_virtual_network_gateway.virtualNetworkGateway.id
    local_network_gateway_id   = azurerm_local_network_gateway.onSiteGateway.id
    shared_key                 = var.vpnPreSharedKey
}