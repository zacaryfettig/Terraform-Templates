resource "azurerm_resource_group" "resourceGroup" {
    name = var.resourceGroup
    location = var.location
}

//keyvautl resources
resource "random_string" "random" {
  length = 6
  special = false
  upper = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyVault" {
  name                        = "keyVault-${random_string.random.result}"
  location                    = azurerm_resource_group.resourceGroup.location
  resource_group_name         = azurerm_resource_group.resourceGroup.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
    ]
  }
}

resource "azurerm_key_vault_secret" "vaultSecret" {
  name         = var.secretName
  value        = var.secret
  key_vault_id = azurerm_key_vault.keyVault.id
  depends_on = [
    azurerm_key_vault.keyVault
  ]
}