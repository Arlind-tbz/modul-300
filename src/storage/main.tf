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

# SSH public key stored as secret
resource "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  value        = var.ssh_public_key
  key_vault_id = azurerm_key_vault.tfvars.id
}

# Startup script stored as secret
resource "azurerm_key_vault_secret" "startup_script" {
  name         = "startup-script"
  value        = var.startup_script
  key_vault_id = azurerm_key_vault.tfvars.id

  lifecycle {
    ignore_changes = [value]
  }
}

# Storage Account for remote tfstate backend
resource "azurerm_storage_account" "tfstate" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.storage_rg.name
  location                 = azurerm_resource_group.storage_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Storage Container to hold tfstate
resource "azurerm_storage_container" "tfstate" {
  name                  = var.storage_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
