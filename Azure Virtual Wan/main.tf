resource "azurerm_resource_group" "resourceGroup" {
    name = var.resourceGroup
    location = var.location
}

####################virtual wan####################
resource "azurerm_virtual_wan" "vwan1" {
  name                = "vwan1"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
}


resource "azurerm_virtual_hub" "vWanHub1" {
  name                = "vWanHub1"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = "10.3.1.0/24"
}



####################First Site To Site VPN Config####################
resource "azurerm_virtual_network" "localVpnVnet" {
  name                = "localVpnSubnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

resource "azurerm_subnet" "localVpnSubnet" {
  name                 = "localVpnSubnet"
  resource_group_name  = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_vpn_gateway" "vpnGateway1" {
  name                = "vpnGateway1"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_hub_id      = azurerm_virtual_hub.vWanHub1.id
}


resource "azurerm_vpn_site" "vpnPhysicalSite" {
  name                = "vpnPhysicalSite"
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
#cidrs address is the On_Prem address space
  address_cidrs = ["10.100.0.0/24"]
  link {
    name       = "Office-Link-1"
    ip_address = var.Public_IP_of_Remote_Gateway
  }
}

resource "azurerm_virtual_hub_connection" "vpnHubConnection1" {
  name                      = "vpnHubConnection1"
  virtual_hub_id            = azurerm_virtual_hub.vWanHub1.id
  remote_virtual_network_id = azurerm_virtual_network.localVpnVnet.id
}

resource "azurerm_vpn_gateway_connection" "gatewayConnection1" {
  name               = "gatewayConnection1"
  vpn_gateway_id     = azurerm_vpn_gateway.vpnGateway1.id
  remote_vpn_site_id = azurerm_vpn_site.vpnPhysicalSite.id

  vpn_link {
    name             = "link1"
    vpn_site_link_id = azurerm_vpn_site.vpnPhysicalSite.link[0].id
  }
}

####################Create and link two vnets to the hub####################

resource "azurerm_virtual_hub_connection" "vnet2Connection" {
  name                      = "vnet2Connection"
  virtual_hub_id            = azurerm_virtual_hub.vWanHub1.id
  remote_virtual_network_id = azurerm_virtual_network.vnet2.id
}

resource "azurerm_virtual_network" "vnet1" {
  name = "vnet1"
  location = var.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space = [ "10.2.0.0/16" ]
}

resource "azurerm_subnet" "vnet1_subnet1" {
  name = "vnet1_subnet1"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes = [ "10.2.1.0/24" ]
}

resource "azurerm_virtual_network" "vnet2" {
  name = "vnet2"
  location = var.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  address_space = [ "10.4.0.0/16" ]
}

resource "azurerm_subnet" "vnet2_subnet1" {
  name = "vnet2_subnet1"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  virtual_network_name = azurerm_virtual_network.vnet2.name
  address_prefixes = [ "10.4.1.0/24" ]
}

resource "azurerm_virtual_hub_connection" "vnet1Connection" {
  name                      = "vnet1Connection"
  virtual_hub_id            = azurerm_virtual_hub.vWanHub1.id
  remote_virtual_network_id = azurerm_virtual_network.vnet1.id
}