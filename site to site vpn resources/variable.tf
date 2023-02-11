variable "resourceGroupName" {
type = string
}

variable "location" {
  type = string
}

variable "localGatewayAddress" {
  description = "local connection public IP"
  type = string
}

variable "localGatewayAddressSpace" {
  description = "local connection address space"
  type = string
}

variable "vpnPreSharedKey" {
  description = "vpn tunnel encryption key"
  type = string
}