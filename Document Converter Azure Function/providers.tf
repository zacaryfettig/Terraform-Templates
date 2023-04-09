terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.42.0"
    }
  }
}

provider "azurerm" {

    features {}
  subscription_id = var.subscriptionID
  tenant_id       = var.tenantID
  use_oidc = true
}

