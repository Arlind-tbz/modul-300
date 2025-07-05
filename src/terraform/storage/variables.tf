variable "location" {
  description = "Azure region to deploy resources"
  default     = "switzerlandnorth"
}

variable "resource_group_name" {
  description = "Name of resource group for storage resources"
  default     = "terraform-storage-rg"
}

variable "key_vault_name" {
  description = "Name of the Key Vault for storing secrets"
  type        = string
  default     = "arlindsulejmanitfvars"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "mysql_root_password" {
  description = "Root password for MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_user" {
  description = "Username for MySQL"
  type        = string
  default     = "root"
  sensitive   = true
}

variable "mysql_password" {
  description = "Password for MySQL user"
  type        = string
  sensitive   = true
}

variable "mysql_database" {
  description = "Database name for MySQL"
  type        = string
  default     = "todo_db"
  sensitive   = true
}

variable "storage_account_name" {
  description = "Globally unique storage account name for Terraform backend"
  type        = string
  default     = "tfstatearlindsulejmani"
}

variable "storage_container_name" {
  description = "Blob container name for tfstate file"
  type        = string
  default     = "tfstate"
}

variable "acr_name" {
  description = "Globally unique name for Azure Container Registry"
  type        = string
  default     = "arlinddevacr"
}
