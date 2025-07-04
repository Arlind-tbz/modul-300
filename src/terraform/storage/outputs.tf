output "key_vault_name" {
  value = azurerm_key_vault.tfvars.name
}

output "key_vault_id" {
  value = azurerm_key_vault.tfvars.id
}

output "resource_group_name" {
  value = azurerm_resource_group.storage_rg.name
}

output "resource_group_location" {
  value = azurerm_resource_group.storage_rg.location
}
