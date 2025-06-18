# outputs.tf - West Europe only setup

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.simpleeshop_rg.name
}

output "control_plane_public_ip" {
  description = "Public IP address of the control plane VM"
  value       = azurerm_public_ip.control_plane_pip.ip_address
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker VMs"
  value       = azurerm_public_ip.worker_pip[*].ip_address
}

output "control_plane_ssh_command" {
  description = "SSH command to connect to control plane"
  value       = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.control_plane_pip.ip_address}"
}

output "worker_ssh_commands" {
  description = "SSH commands to connect to worker VMs"
  value = [
    for i, ip in azurerm_public_ip.worker_pip : 
    "ssh -i ~/.ssh/azure_rsa azureuser@${ip.ip_address}  # Worker ${i + 1}"
  ]
}

output "all_ssh_commands" {
  description = "All SSH commands for easy access"
  value = {
    control_plane = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.control_plane_pip.ip_address}"
    workers = [
      for i, ip in azurerm_public_ip.worker_pip : 
      "ssh -i ~/.ssh/azure_rsa azureuser@${ip.ip_address}"
    ]
  }
}

output "application_urls" {
  description = "URLs to access the applications"
  value = {
    # Control plane services
    jenkins     = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30080"
    argocd      = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30090"
    grafana     = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30030"
    
    # Application services (running on workers)
    simpleeshop = length(azurerm_public_ip.worker_pip) > 0 ? "http://${azurerm_public_ip.worker_pip[0].ip_address}:30000" : "No workers available"
    
    # Storage services
    minio = length(azurerm_public_ip.worker_pip) > 0 ? "http://${azurerm_public_ip.worker_pip[0].ip_address}:30900" : "No workers available"
  }
}

output "kubernetes_cluster_info" {
  description = "Information about the Kubernetes cluster"
  value = {
    control_plane   = azurerm_public_ip.control_plane_pip.ip_address
    workers         = azurerm_public_ip.worker_pip[*].ip_address
    total_workers   = var.worker_count
    region          = var.location
  }
}

output "network_info" {
  description = "Network configuration details"
  value = {
    vnet = {
      name          = azurerm_virtual_network.simpleeshop_vnet.name
      address_space = azurerm_virtual_network.simpleeshop_vnet.address_space[0]
      location      = azurerm_virtual_network.simpleeshop_vnet.location
    }
  }
}

output "ansible_inventory_ips" {
  description = "IP addresses formatted for Ansible inventory"
  value = {
    control_plane = azurerm_public_ip.control_plane_pip.ip_address
    workers       = azurerm_public_ip.worker_pip[*].ip_address
  }
}