variable "resourceGroup" {
  type = string
  default = "rg57"
}

variable "location" {
  type = string
  default = "westus3"
}

variable "subscriptionID" {
  type = string
  description = "description"
  default = null
}

variable "tenantID" {
  type = string
  description = "description"
  default = null
}