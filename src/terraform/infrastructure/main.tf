provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# --- Key Vault Lookup (for secret integration) ---
data "azurerm_key_vault" "tfvars" {
  name                = var.key_vault_name
  resource_group_name = var.storage_resource_group_name
}

# --- Client Config (for role assignments) ---
data "azurerm_client_config" "current" {}

# --- ACR Lookup ---
data "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.storage_resource_group_name
}

# --- Storage Account & Blob Container for DB Volumes ---
resource "azurerm_storage_account" "db_storage" {
  name                     = "dbstorage${var.project_name}"
  resource_group_name      = azurerm_resource_group.infra_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "db_share" {
  name                 = "db-volume"
  storage_account_name = azurerm_storage_account.db_storage.name
  quota                = 5
}

# --- Resource Group ---
resource "azurerm_resource_group" "infra_rg" {
  name     = var.resource_group_name
  location = var.location
}

# --- Virtual Network & Subnet ---
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

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# --- Container App Environment ---
resource "azurerm_container_app_environment" "env" {
  name                 = "${var.project_name}-env"
  location             = var.location
  resource_group_name  = azurerm_resource_group.infra_rg.name
}

# --- DB Container App (with Azure File volume and secrets) ---
resource "azurerm_container_app" "db" {
  name                          = "${var.project_name}-db"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  location                      = var.location
  revision_mode                 = "Single"

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = false
    target_port      = 5432
    transport        = "auto"
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = "SystemAssigned"
  }

  secret {
    name  = "mysql-root-password"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-root-password)"
  }

  template {
    container {
      name   = "db"
      image  = "${data.azurerm_container_registry.acr.login_server}/db:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }

      volume_mounts {
        name       = "dbvolume"
        mount_path = "/var/lib/mysql"
      }
    }

    volume {
      name       = "dbvolume"
      storage_type = "AzureFile"
      storage_account_name = azurerm_storage_account.db_storage.name
      storage_share_name   = azurerm_storage_share.db_share.name
    }
  }
}

# --- Backend Container App ---
resource "azurerm_container_app" "backend" {
  name                          = "${var.project_name}-backend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  location                      = var.location
  revision_mode                 = "Single"

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true
    target_port      = 4000
    transport        = "auto"
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = "SystemAssigned"
  }

  secret {
    name  = "mysql-password"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-password)"
  }

  template {
    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "MYSQL_HOST"
        value = "db"
      }
      env {
        name  = "MYSQL_USER"
        secret_name = "mysql_user"
      }
      env {
        name  = "MYSQL_PASSWORD"
        secret_name = "mysql-password"
      }
      env {
        name  = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }
      env {
        name  = "MYSQL_DATABASE"
        secret_name = "mysql_database"
      }
    }
  }
}

# --- Frontend Container App ---
resource "azurerm_container_app" "frontend" {
  name                          = "${var.project_name}-frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  location                      = var.location
  revision_mode                 = "Single"

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"
  }

  registry {
    server   = data.azurerm_container_registry.acr.login_server
    identity = "SystemAssigned"
  }

  template {
    container {
      name   = "frontend"
      image  = "${data.azurerm_container_registry.acr.login_server}/frontend:latest"
      cpu    = 0.5
      memory = "1.0Gi"
    }
  }
}

# --- Role Assignments ---
resource "azurerm_role_assignment" "acr_pull_frontend" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.frontend.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull_backend" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.backend.identity[0].principal_id
}

resource "azurerm_role_assignment" "acr_pull_db" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_container_app.db.identity[0].principal_id
}
