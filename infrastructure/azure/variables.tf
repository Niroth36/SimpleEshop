variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "simpleeshop-cloud-rg"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "West Europe"
}

variable "sub_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
}

variable "email" {
  description = "Email for notifications"
  type        = string
}

variable "control_plane_vm_size" {
  description = "Size of the control plane VM"
  type        = string
  default     = "Standard_B1s"
}

variable "worker_vm_size" {
  description = "Size of the worker VMs"
  type        = string
  default     = "Standard_B1s"
}

variable "worker_count" {
  description = "Number of worker VMs to create"
  type        = number
  default     = 2
  
  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 5
    error_message = "Worker count must be between 1 and 5."
  }
}