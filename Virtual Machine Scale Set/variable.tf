variable "resourceGroupName" {
type = string
}

variable "location" {
  type = string
}

variable "vmUsername" {
  type = string
}

variable "vmPassword" {
  type = string
}

variable "publisher" {
  type = string
  default = "MicrosoftWindowsServer"
}

variable "offer" {
  type = string
  default = "WindowsServer"
}

variable "sku" {
  type = string
  default = "2019-Datacenter"
}

variable "version" {
  type = string
  default = "latest"
}