# variables.tf - Updated for multi-region setup

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
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_B4ms", 
      "Standard_D2s_v3", "Standard_D4s_v3"
    ], var.control_plane_vm_size)
    error_message = "Control plane VM size must be appropriate for Kubernetes workloads."
  }
}

variable "worker_vm_size" {
  description = "Size of the worker VMs (applies to both West Europe and Sweden workers)"
  type        = string
  default     = "Standard_B2s"
  
  validation {
    condition = contains([
      "Standard_B1s", "Standard_B2s", "Standard_B2ms", "Standard_B4ms",
      "Standard_D2s_v3", "Standard_D4s_v3"
    ], var.worker_vm_size)
    error_message = "Worker VM size must be appropriate for Kubernetes workloads."
  }
}

variable "worker_count" {
  description = "Number of worker VMs to create in West Europe"
  type        = number
  default     = 1  # Changed from 2 to 1 for quota compliance
  
  validation {
    condition     = var.worker_count >= 1 && var.worker_count <= 3
    error_message = "Worker count must be between 1 and 3 (due to quota limits)."
  }
}
