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
  value       = "ssh azureuser@${azurerm_public_ip.control_plane_pip.ip_address}"
}

output "worker_ssh_commands" {
  description = "SSH commands to connect to worker VMs"
  value = [
    for i, ip in azurerm_public_ip.worker_pip : 
    "ssh azureuser@${ip.ip_address}  # Worker ${i + 1}"
  ]
}

output "application_urls" {
  description = "URLs to access the applications"
  value = {
    jenkins          = "http://${azurerm_public_ip.control_plane_pip.ip_address}:8080"
    argocd          = "http://${azurerm_public_ip.control_plane_pip.ip_address}:8090"
    simpleeshop     = "http://${azurerm_public_ip.worker_pip[0].ip_address}:3000"
    grafana         = length(azurerm_public_ip.worker_pip) > 1 ? "http://${azurerm_public_ip.worker_pip[1].ip_address}:3001" : "Will be available when worker-2 is deployed"
    minio           = "http://${azurerm_public_ip.worker_pip[0].ip_address}:9001"
  }
}

output "kubernetes_cluster_info" {
  description = "Information about the Kubernetes cluster"
  value = {
    control_plane = azurerm_public_ip.control_plane_pip.ip_address
    workers       = azurerm_public_ip.worker_pip[*].ip_address
    worker_count  = var.worker_count
  }
}