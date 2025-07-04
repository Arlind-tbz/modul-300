provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

data "azurerm_key_vault" "tfvars" {
  name                = var.key_vault_name
  resource_group_name = var.storage_resource_group_name
}

# Retrieve SSH key from Key Vault
data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = "ssh-public-key"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

# Retrieve startup script from Key Vault
data "azurerm_key_vault_secret" "startup_script" {
  name         = "startup-script"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

resource "azurerm_resource_group" "infra_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.infra_rg.name
  location            = azurerm_resource_group.infra_rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.infra_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.vm_name}-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = var.nic_name
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = azurerm_resource_group.infra_rg.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = data.azurerm_key_vault_secret.ssh_public_key.value
  }

  custom_data = base64encode(data.azurerm_key_vault_secret.startup_script.value)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "myosdisk1"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
