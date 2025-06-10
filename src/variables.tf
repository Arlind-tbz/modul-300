variable "location" {
  description = "Azure region to deploy resources"
  default     = "switzerlandnorth"
}

variable "resource_group_name" {
  default = "example-resources"
}


variable "vnet_name" {
  default = "example-vnet"
}

variable "subnet_name" {
  default = "example-subnet"
}

variable "nic_name" {
  default = "example-nic"
}

variable "vm_name" {
  default = "example-vm"
}

variable "admin_username" {
  default = "azureuser"
}

variable "vm_size" {
  default = "Standard_B1s"
}

variable "ssh_public_key" {
  description = "Your SSH public key"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "startup_script" {
  description = "cloud-init startup script"
  type        = string
  default     = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get upgrade
  EOT
}
