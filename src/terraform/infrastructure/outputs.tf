output "frontend_url" {
  value = azurerm_container_app.frontend.latest_revision_fqdn
}
