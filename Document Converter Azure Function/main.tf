resource "random_string" "random" {
  length           = 8
  special          = false
  upper            = false
}

resource "azurerm_resource_group" "resourceGroup" {
    name = var.resourceGroup
    location = var.location
}

resource "azurerm_storage_account" "storageAccount" {
  name                     = "storage${random_string.random.result}"
  resource_group_name      = var.resourceGroup
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  depends_on = [azurerm_resource_group.resourceGroup]
}

resource "azurerm_service_plan" "servicePlan" {
  name                = "functionServicePlan"
  resource_group_name = var.resourceGroup
  location            = var.location
  os_type             = "Windows"
  sku_name            = "Y1"
    depends_on = [azurerm_storage_account.storageAccount]
}

resource "azurerm_windows_function_app" "functionApp" {
  name                = "functionappdocconverter5846"
  resource_group_name = var.resourceGroup
  location            = var.location

  storage_account_name       = azurerm_storage_account.storageAccount.name
  storage_account_access_key = azurerm_storage_account.storageAccount.primary_access_key
  service_plan_id            = azurerm_service_plan.servicePlan.id
  
  site_config {
  }
}