variable "resource_group_name" {
  description = "Name of resource group for infrastructure"
  type        = string
  default     = "terraform-infrastructure-rg"
}

variable "storage_resource_group_name" {
  description = "Name of resource group containing the Key Vault"
  type        = string
  default     = "terraform-storage-rg"
}

variable "key_vault_name" {
  description = "Name of existing Key Vault for retrieving secrets"
  type        = string
  default     = "arlindsulejmanitfvars"
}

variable "location" {
  description = "Azure region (should match storage deployment)"
  type        = string
  default     = "switzerlandnorth"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "acr_name" {
  description = "Globally unique name for Azure Container Registry"
  type        = string
  default     = "arlinddevacr"
}

variable "project_name" {
  description = "Prefix used for naming resources"
  type        = string
  default     = "arlindapp"
}
