terraform {
    required_providers {
        source = "hashicorp/azurerm"
        required_version = ">= 0.12"
    }
}

provider "azurerm" {
    features {}
}