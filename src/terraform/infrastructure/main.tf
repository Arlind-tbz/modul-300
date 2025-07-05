provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# --- Key Vault Lookup ---
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

# --- ACR Credentials from Key Vault ---
data "azurerm_key_vault_secret" "acr_username" {
  name         = "acr-username"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

data "azurerm_key_vault_secret" "acr_password" {
  name         = "acr-password"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

resource "azurerm_resource_provider_registration" "container_apps" {
  name = "Microsoft.App"
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

# --- User Assigned Identities ---
resource "azurerm_user_assigned_identity" "frontend_identity" {
  name                = "${var.project_name}-frontend-id"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
}

resource "azurerm_user_assigned_identity" "backend_identity" {
  name                = "${var.project_name}-backend-id"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
}

resource "azurerm_user_assigned_identity" "db_identity" {
  name                = "${var.project_name}-db-id"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
}

# --- Container App Environment ---
resource "azurerm_container_app_environment" "env" {
  name                 = "${var.project_name}-env"
  location             = var.location
  resource_group_name  = azurerm_resource_group.infra_rg.name

  depends_on = [azurerm_resource_provider_registration.container_apps]
}

# --- Backend Container App ---
resource "azurerm_container_app" "backend" {
  name                          = "${var.project_name}-backend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  revision_mode                 = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend_identity.id]
  }

  ingress {
    external_enabled = false
    target_port      = 5000
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_key_vault_secret.acr_username.value
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = data.azurerm_key_vault_secret.acr_password.value
  }

  secret {
    name  = "mysql-user"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-user)"
  }

  secret {
    name  = "mysql-database"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-database)"
  }

  secret {
    name  = "mysql-password"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-password)"
  }

  secret {
    name  = "mysql-root-password"
    value = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.tfvars.name};SecretName=mysql-root-password)"
  }

  template {
    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name        = "MYSQL_USER"
        secret_name = "mysql-user"
      }
      env {
        name        = "MYSQL_PASSWORD"
        secret_name = "mysql-password"
      }
      env {
        name        = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }
      env {
        name        = "MYSQL_DATABASE"
        secret_name = "mysql-database"
      }
    }
  }
}

# --- DB Container App ---
resource "azurerm_container_app" "db" {
  name                          = "${var.project_name}-db"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  revision_mode                 = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.db_identity.id]
  }

  ingress {
    external_enabled = false
    target_port      = 5432
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_key_vault_secret.acr_username.value
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = data.azurerm_key_vault_secret.acr_password.value
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
        name        = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }
    }
  }
}

# --- Frontend Container App ---
resource "azurerm_container_app" "frontend" {
  name                          = "${var.project_name}-frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name           = azurerm_resource_group.infra_rg.name
  revision_mode                 = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.frontend_identity.id]
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  registry {
    server               = data.azurerm_container_registry.acr.login_server
    username             = data.azurerm_key_vault_secret.acr_username.value
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = data.azurerm_key_vault_secret.acr_password.value
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
