# Configure the Azure Provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.75.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = false
    }
  }
  subscription_id = var.sub_id
  skip_provider_registration = true  # Add this line for Azure for Students
}

# Create Resource Group
resource "azurerm_resource_group" "simpleeshop_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
    Purpose     = "University-Project"
  }
}

# Create Virtual Network
resource "azurerm_virtual_network" "simpleeshop_vnet" {
  name                = "simpleeshop-vnet"
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name
  location            = azurerm_resource_group.simpleeshop_rg.location
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

# Create Subnets
resource "azurerm_subnet" "control_plane_subnet" {
  name                 = "control-plane-subnet"
  resource_group_name  = azurerm_resource_group.simpleeshop_rg.name
  virtual_network_name = azurerm_virtual_network.simpleeshop_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "worker_subnet" {
  name                 = "worker-subnet"
  resource_group_name  = azurerm_resource_group.simpleeshop_rg.name
  virtual_network_name = azurerm_virtual_network.simpleeshop_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# Create Network Security Groups
resource "azurerm_network_security_group" "control_plane_nsg" {
  name                = "control-plane-nsg"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Kubernetes API Server
  security_rule {
    name                       = "K8s-API"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Jenkins
  security_rule {
    name                       = "Jenkins"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ArgoCD
  security_rule {
    name                       = "ArgoCD"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8090"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Add this to your control_plane_nsg in main.tf
  security_rule {
    name                       = "MicroK8s-API-External"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "16443"
    source_address_prefix      = "*"  # Or restrict to your IP for security
    destination_address_prefix = "*"
  }

  # Microk8s
  security_rule {
    name                       = "K8s-API-External"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6443"
    source_address_prefix      = "*"  # Change to your IP for security
    destination_address_prefix = "*"
  }

  # NodePort range for Kubernetes services
  security_rule {
    name                       = "K8s-NodePort"
    priority                   = 1007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

resource "azurerm_network_security_group" "worker_nsg" {
  name                = "worker-nsg"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # SimpleEshop Application
  security_rule {
    name                       = "SimpleEshop"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # MinIO
  security_rule {
    name                       = "MinIO"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000-9001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Grafana
  security_rule {
    name                       = "Grafana"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3001"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # NodePort range for Kubernetes services
  security_rule {
    name                       = "K8s-NodePort"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30000-32767"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ArgoCD HTTPS
  security_rule {
    name                       = "ArgoCD-HTTPS"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

# Create Public IPs
resource "azurerm_public_ip" "control_plane_pip" {
  name                = "control-plane-pip"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

resource "azurerm_public_ip" "worker_pip" {
  count               = var.worker_count
  name                = "worker-${count.index + 1}-pip"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
    Role        = "Worker-${count.index + 1}"
  }
}

# Create Network Interfaces
resource "azurerm_network_interface" "control_plane_nic" {
  name                = "control-plane-nic"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.control_plane_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.control_plane_pip.id
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

resource "azurerm_network_interface" "worker_nic" {
  count               = var.worker_count
  name                = "worker-${count.index + 1}-nic"
  location            = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name = azurerm_resource_group.simpleeshop_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.worker_pip[count.index].id
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
    Role        = "Worker-${count.index + 1}"
  }
}

# Associate Network Security Groups to Network Interfaces
resource "azurerm_network_interface_security_group_association" "control_plane_nsg_association" {
  network_interface_id      = azurerm_network_interface.control_plane_nic.id
  network_security_group_id = azurerm_network_security_group.control_plane_nsg.id
}

resource "azurerm_network_interface_security_group_association" "worker_nsg_association" {
  count                     = var.worker_count
  network_interface_id      = azurerm_network_interface.worker_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.worker_nsg.id
}

# Create Control Plane VM
resource "azurerm_linux_virtual_machine" "control_plane_vm" {
  name                  = "control-plane-vm"
  location              = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name   = azurerm_resource_group.simpleeshop_rg.name
  network_interface_ids = [azurerm_network_interface.control_plane_nic.id]
  size                  = var.control_plane_vm_size
  admin_username        = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "control-plane-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
    Role        = "Control-Plane"
  }
}

# Create Worker VMs
resource "azurerm_linux_virtual_machine" "worker_vm" {
  count                 = var.worker_count
  name                  = "worker-${count.index + 1}-vm"
  location              = azurerm_resource_group.simpleeshop_rg.location
  resource_group_name   = azurerm_resource_group.simpleeshop_rg.name
  network_interface_ids = [azurerm_network_interface.worker_nic[count.index].id]
  size                  = var.worker_vm_size
  admin_username        = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "worker-${count.index + 1}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
    Role        = "Worker-${count.index + 1}"
  }
}

# Auto-shutdown schedule for all VMs
resource "azurerm_dev_test_global_vm_shutdown_schedule" "control_plane_shutdown" {
  virtual_machine_id = azurerm_linux_virtual_machine.control_plane_vm.id
  location           = azurerm_resource_group.simpleeshop_rg.location

  daily_recurrence_time = "0200"
  timezone              = "E. Europe Standard Time"
  enabled               = true

  notification_settings {
    enabled         = true
    email           = var.email
    time_in_minutes = 30
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "worker_shutdown" {
  count              = var.worker_count
  virtual_machine_id = azurerm_linux_virtual_machine.worker_vm[count.index].id
  location           = azurerm_resource_group.simpleeshop_rg.location

  daily_recurrence_time = "0200"
  timezone              = "E. Europe Standard Time"
  enabled               = true

  notification_settings {
    enabled         = true
    email           = var.email
    time_in_minutes = 30
  }

  tags = {
    Environment = "Development"
    Project     = "SimpleEshop-Cloud"
  }
}

# Generate SSH config for easy access
resource "local_file" "ssh_config" {
  content = templatefile("${path.module}/ssh_config.tpl", {
    control_plane_ip = azurerm_public_ip.control_plane_pip.ip_address,
    worker_ips       = azurerm_public_ip.worker_pip[*].ip_address,
    worker_count     = var.worker_count
  })

  filename = "/tmp/simpleeshop_ssh_config"
}

resource "null_resource" "update_ssh_config" {
  provisioner "local-exec" {
    command = <<EOF
      echo "# SimpleEshop Cloud Infrastructure" >> ~/.ssh/config
      cat /tmp/simpleeshop_ssh_config >> ~/.ssh/config
      echo "" >> ~/.ssh/config
    EOF
  }

  depends_on = [local_file.ssh_config]
}
