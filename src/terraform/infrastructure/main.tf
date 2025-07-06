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

data "azurerm_key_vault_secret" "mysql_user" {
  name         = "mysql-user"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

data "azurerm_key_vault_secret" "mysql_password" {
  name         = "mysql-password"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

data "azurerm_key_vault_secret" "mysql_database" {
  name         = "mysql-database"
  key_vault_id = data.azurerm_key_vault.tfvars.id
}

data "azurerm_key_vault_secret" "mysql_root_password" {
  name         = "mysql-root-password"
  key_vault_id = data.azurerm_key_vault.tfvars.id
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
  name                = "${var.project_name}-env"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name

  depends_on = [azurerm_resource_provider_registration.container_apps]
}

# --- Backend Container App ---
resource "azurerm_container_app" "backend" {
  depends_on                   = [azurerm_container_app.db]
  name                         = "${var.project_name}-backend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.infra_rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.backend_identity.id]
  }

  ingress {
    external_enabled = false
    target_port      = 5000
    transport        = "tcp"

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
    value = data.azurerm_key_vault_secret.mysql_user.value
  }

  secret {
    name  = "mysql-password"
    value = data.azurerm_key_vault_secret.mysql_password.value
  }

  secret {
    name  = "mysql-database"
    value = data.azurerm_key_vault_secret.mysql_database.value
  }

  secret {
    name  = "mysql-root-password"
    value = data.azurerm_key_vault_secret.mysql_root_password.value
  }

  template {
    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "MYSQL_HOST"
        value = "${var.project_name}-db"
      }

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
  name                         = "${var.project_name}-db"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.infra_rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.db_identity.id]
  }

  ingress {
    external_enabled = false
    target_port      = 3306
    transport        = "tcp"

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
    value = data.azurerm_key_vault_secret.mysql_root_password.value
  }

  template {
    container {
      name   = "db"
      image  = "${data.azurerm_container_registry.acr.login_server}/db:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }

      volume_mount {
        name = "ephemeral-storage"
        path = "/var/lib/mysql"
      }
    }

    volume {
      name         = "ephemeral-storage"
      storage_type = "EmptyDir"
    }
  }
}

# --- Frontend Container App ---
resource "azurerm_container_app" "frontend" {
  depends_on                   = [azurerm_container_app.backend]
  name                         = "${var.project_name}-frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.infra_rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.frontend_identity.id]
  }

  ingress {
    external_enabled = true
    target_port      = 8080
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
      memory = "1Gi"

      env {
        name  = "BACKEND_HOST"
        value = "${var.project_name}-backend"
      }
    }
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-appinsights"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}

resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-alerts"
  resource_group_name = azurerm_resource_group.infra_rg.name
  short_name          = "alerts"

  email_receiver {
    name          = "admin"
    email_address = "arlind@sulej.ch"
  }
}

resource "azurerm_monitor_metric_alert" "backend_health" {
  name                = "${var.project_name}-backend-unhealthy"
  resource_group_name = azurerm_resource_group.infra_rg.name
  scopes              = [azurerm_container_app.backend.id]

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Replicas"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_metric_alert" "frontend_error_rate" {
  name                = "${var.project_name}-frontend-5xx"
  resource_group_name = azurerm_resource_group.infra_rg.name
  scopes              = [azurerm_container_app.frontend.id]

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Requests"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 100

    dimension {
      name     = "statusCodeCategory"
      operator = "Include"
      values   = ["5xx"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}


resource "azurerm_monitor_metric_alert" "db_high_cpu" {
  name                = "${var.project_name}-db-high-cpu"
  resource_group_name = azurerm_resource_group.infra_rg.name
  scopes              = [azurerm_container_app.db.id]

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "CpuUsagePercentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}
