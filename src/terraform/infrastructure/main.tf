provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

data "azurerm_key_vault" "tfvars" {
  name                = var.key_vault_name
  resource_group_name = var.storage_resource_group_name
}

data "azurerm_client_config" "current" {}

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

resource "azurerm_resource_group" "infra_rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "mysql_storage" {
  name                     = "${replace(var.project_name, "-", "")}mysqlsa"
  resource_group_name      = azurerm_resource_group.infra_rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version = "TLS1_2"

  tags = {
    environment = "production"
    purpose     = "mysql-data"
  }
}

resource "azurerm_storage_share" "mysql_data" {
  name               = "mysql-data"
  storage_account_id = azurerm_storage_account.mysql_storage.id
  quota              = 1

  depends_on = [azurerm_storage_account.mysql_storage]
}

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

resource "azurerm_container_app_environment" "env" {
  name                = "${var.project_name}-env"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name

  depends_on = [azurerm_resource_provider_registration.container_apps]
}

resource "azurerm_container_app_environment_storage" "mysql_storage" {
  name                         = "mysql-data-storage"
  container_app_environment_id = azurerm_container_app_environment.env.id
  account_name                 = azurerm_storage_account.mysql_storage.name
  share_name                   = azurerm_storage_share.mysql_data.name
  access_key                   = azurerm_storage_account.mysql_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

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
    min_replicas = 1

    volume {
      name         = "mysql-data-volume"
      storage_name = azurerm_container_app_environment_storage.mysql_storage.name
      storage_type = "AzureFile"
    }

    container {
      name   = "backend"
      image  = "${data.azurerm_container_registry.acr.login_server}/backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      volume_mounts {
        name = "mysql-data-volume"
        path = "/app/data/"
      }

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
    min_replicas = 1

    container {
      name   = "db"
      image  = "${data.azurerm_container_registry.acr.login_server}/db:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name        = "MYSQL_ROOT_PASSWORD"
        secret_name = "mysql-root-password"
      }
    }
  }
}

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
    min_replicas = 1
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

resource "azurerm_recovery_services_vault" "backup_vault" {
  name                = "${var.project_name}-vault"
  location            = var.location
  resource_group_name = azurerm_resource_group.infra_rg.name
  sku                 = "Standard"
  soft_delete_enabled = true
}

resource "azurerm_backup_policy_file_share" "file_share_policy" {
  name                = "daily-policy"
  resource_group_name = azurerm_resource_group.infra_rg.name
  recovery_vault_name = azurerm_recovery_services_vault.backup_vault.name

  timezone = "UTC"
  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_file_share" "mysql_data_backup" {
  resource_group_name      = azurerm_resource_group.infra_rg.name
  recovery_vault_name      = azurerm_recovery_services_vault.backup_vault.name
  source_storage_account_id = azurerm_storage_account.mysql_storage.id
  source_file_share_name   = azurerm_storage_share.mysql_data.name
  backup_policy_id         = azurerm_backup_policy_file_share.file_share_policy.id
}
