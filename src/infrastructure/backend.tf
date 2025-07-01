terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-storage-rg"
    storage_account_name = "tfstatestorearlindsulejmani"
    container_name       = "tfstate"
    key                  = "infrastructure.tfstate"
  }
}
