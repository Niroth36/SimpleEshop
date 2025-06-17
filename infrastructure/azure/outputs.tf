# outputs.tf - Updated for multi-region setup

output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.simpleeshop_rg.name
}

output "sweden_resource_group_name" {
  description = "Name of the Sweden resource group"
  value       = azurerm_resource_group.simpleeshop_sweden_rg.name
}

output "control_plane_public_ip" {
  description = "Public IP address of the control plane VM"
  value       = azurerm_public_ip.control_plane_pip.ip_address
}

output "worker_public_ips" {
  description = "Public IP addresses of the West Europe worker VMs"
  value       = azurerm_public_ip.worker_pip[*].ip_address
}

output "sweden_worker_public_ip" {
  description = "Public IP address of the Sweden worker VM"
  value       = azurerm_public_ip.sweden_worker_pip.ip_address
}

output "all_worker_ips" {
  description = "All worker IP addresses (West Europe + Sweden)"
  value = concat(
    azurerm_public_ip.worker_pip[*].ip_address,
    [azurerm_public_ip.sweden_worker_pip.ip_address]
  )
}

output "control_plane_ssh_command" {
  description = "SSH command to connect to control plane"
  value       = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.control_plane_pip.ip_address}"
}

output "worker_ssh_commands" {
  description = "SSH commands to connect to West Europe worker VMs"
  value = [
    for i, ip in azurerm_public_ip.worker_pip : 
    "ssh -i ~/.ssh/azure_rsa azureuser@${ip.ip_address}  # West Europe Worker ${i + 1}"
  ]
}

output "sweden_worker_ssh_command" {
  description = "SSH command to connect to Sweden worker"
  value       = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.sweden_worker_pip.ip_address}  # Sweden Worker"
}

output "all_ssh_commands" {
  description = "All SSH commands for easy access"
  value = {
    control_plane    = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.control_plane_pip.ip_address}"
    west_europe_workers = [
      for i, ip in azurerm_public_ip.worker_pip : 
      "ssh -i ~/.ssh/azure_rsa azureuser@${ip.ip_address}"
    ]
    sweden_worker   = "ssh -i ~/.ssh/azure_rsa azureuser@${azurerm_public_ip.sweden_worker_pip.ip_address}"
  }
}

output "application_urls" {
  description = "URLs to access the applications"
  value = {
    # Control plane services
    jenkins     = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30080"
    argocd      = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30090"
    grafana     = "http://${azurerm_public_ip.control_plane_pip.ip_address}:30030"
    
    # Application services (can run on any worker)
    simpleeshop_west_europe = length(azurerm_public_ip.worker_pip) > 0 ? "http://${azurerm_public_ip.worker_pip[0].ip_address}:30000" : "No West Europe workers available"
    simpleeshop_sweden      = "http://${azurerm_public_ip.sweden_worker_pip.ip_address}:30000"
    
    # Storage services
    minio_west_europe = length(azurerm_public_ip.worker_pip) > 0 ? "http://${azurerm_public_ip.worker_pip[0].ip_address}:30900" : "No West Europe workers available"
    minio_sweden      = "http://${azurerm_public_ip.sweden_worker_pip.ip_address}:30900"
  }
}

output "kubernetes_cluster_info" {
  description = "Information about the Kubernetes cluster"
  value = {
    control_plane        = azurerm_public_ip.control_plane_pip.ip_address
    west_europe_workers  = azurerm_public_ip.worker_pip[*].ip_address
    sweden_worker        = azurerm_public_ip.sweden_worker_pip.ip_address
    total_workers        = var.worker_count + 1  # West Europe workers + Sweden worker
    regions              = ["West Europe", "Sweden Central"]
  }
}

output "network_info" {
  description = "Network configuration details"
  value = {
    west_europe_vnet = {
      name          = azurerm_virtual_network.simpleeshop_vnet.name
      address_space = azurerm_virtual_network.simpleeshop_vnet.address_space[0]
      location      = azurerm_virtual_network.simpleeshop_vnet.location
    }
    sweden_vnet = {
      name          = azurerm_virtual_network.simpleeshop_sweden_vnet.name
      address_space = azurerm_virtual_network.simpleeshop_sweden_vnet.address_space[0]
      location      = azurerm_virtual_network.simpleeshop_sweden_vnet.location
    }
  }
}

output "ansible_inventory_ips" {
  description = "IP addresses formatted for Ansible inventory"
  value = {
    control_plane = azurerm_public_ip.control_plane_pip.ip_address
    workers = {
      west_europe = azurerm_public_ip.worker_pip[*].ip_address
      sweden      = azurerm_public_ip.sweden_worker_pip.ip_address
    }
  }
}