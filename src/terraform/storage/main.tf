provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Data source to get current client config
data "azurerm_client_config" "current" {}

# Create dedicated resource group for storage
resource "azurerm_resource_group" "storage_rg" {
  name     = var.resource_group_name
  location = var.location
}

# Key Vault for storing sensitive tfvars
resource "azurerm_key_vault" "tfvars" {
  name                = var.key_vault_name
  location            = azurerm_resource_group.storage_rg.location
  resource_group_name = azurerm_resource_group.storage_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Disable purge protection for easier management
  purge_protection_enabled   = false
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "mysql_root_password" {
  name         = "mysql-root-password"
  value        = var.mysql_root_password
  key_vault_id = azurerm_key_vault.tfvars.id
}

resource "azurerm_key_vault_secret" "mysql_user" {
  name         = "mysql-user"
  value        = var.mysql_user
  key_vault_id = azurerm_key_vault.tfvars.id
}

resource "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-password"
  value        = var.mysql_password
  key_vault_id = azurerm_key_vault.tfvars.id
}

resource "azurerm_key_vault_secret" "mysql_database" {
  name         = "mysql-database"
  value        = var.mysql_database
  key_vault_id = azurerm_key_vault.tfvars.id
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.storage_rg.name
  location            = azurerm_resource_group.storage_rg.location
  sku                 = "Basic"
  admin_enabled       = false
}
