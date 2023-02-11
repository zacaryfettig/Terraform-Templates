variable "resourceGroupName" {
type = string
}
variable "resoureGroupLocation" {
  type = string
}

variable "email_address" {
  type = string
}

variable "storageAccountType" {
  type = string
  default = "Standard_LRS"
}


//VM
variable "vmSize" {
  type = string
  default = "Standard_F4s_v2"
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

variable "vmUsername" {
  type = string
}

variable "vmPassword" {
  type = string
}


//metrics
variable "metric_namespace" {
  type = string
  default = "Microsoft.Compute/virtualMachines"
}

variable "metric_name" {
  type = string
  default = "Percentage CPU"
}

variable "aggregation" {
  type = string
  default = "Total"
}

variable "operator" {
  type = string
  default = "GreaterThan"
}

variable "threshold" {
  type = number
  default = 70
}