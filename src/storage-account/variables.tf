variable "location" {
  description = "Azure region to deploy resources"
  default     = "switzerlandnorth"
}

variable "resource_group_name" {
  description = "Name of the resource group for the backend"
  default     = "tfstate-rg"
}

variable "storage_account_name" {
  description = "Globally unique name for the Terraform backend storage account"
  default     = "tfstatebackend1234"
}

variable "container_name" {
  description = "Name of the blob container to store the tfstate file"
  default     = "tfstate"
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}
