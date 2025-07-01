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

variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
  sensitive   = true
}

variable "startup_script" {
  description = "cloud-init startup script"
  type        = string
  sensitive   = true
  default     = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get upgrade
  EOT
}

variable "storage_account_name" {
  description = "Globally unique storage account name for Terraform backend"
  type        = string
  default     = "tfstatestorearlindsulejmani"
}

variable "storage_container_name" {
  description = "Blob container name for tfstate file"
  type        = string
  default     = "tfstate"
}
