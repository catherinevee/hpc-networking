# Basic Azure HPC Networking Example
# Simple 8-node training cluster with InfiniBand and Azure NetApp Files

terraform {
  required_version = "1.12.2"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.95.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "hpc" {
  name     = "hpc-networking-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "hpc" {
  name                = "hpc-vnet"
  resource_group_name = azurerm_resource_group.hpc.name
  location            = azurerm_resource_group.hpc.location
  address_space       = ["10.0.0.0/16"]
}

# Subnets
resource "azurerm_subnet" "compute" {
  name                 = "compute-subnet"
  resource_group_name  = azurerm_resource_group.hpc.name
  virtual_network_name = azurerm_virtual_network.hpc.name
  address_prefixes     = ["10.0.10.0/22"]
}

resource "azurerm_subnet" "storage" {
  name                 = "storage-subnet"
  resource_group_name  = azurerm_resource_group.hpc.name
  virtual_network_name = azurerm_virtual_network.hpc.name
  address_prefixes     = ["10.0.20.0/24"]
}

resource "azurerm_subnet" "endpoints" {
  name                 = "endpoints-subnet"
  resource_group_name  = azurerm_resource_group.hpc.name
  virtual_network_name = azurerm_virtual_network.hpc.name
  address_prefixes     = ["10.0.30.0/24"]
}

# Network Security Group for Compute
resource "azurerm_network_security_group" "compute" {
  name                = "compute-nsg"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "InfiniBand"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.10.0/22"
    destination_address_prefix = "*"
  }
}

# Network Security Group for Storage
resource "azurerm_network_security_group" "storage" {
  name                = "storage-nsg"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name

  security_rule {
    name                       = "NFS"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "2049"
    source_address_prefix      = "10.0.10.0/22"
    destination_address_prefix = "*"
  }
}

# Subnet NSG Associations
resource "azurerm_subnet_network_security_group_association" "compute" {
  subnet_id                 = azurerm_subnet.compute.id
  network_security_group_id = azurerm_network_security_group.compute.id
}

resource "azurerm_subnet_network_security_group_association" "storage" {
  subnet_id                 = azurerm_subnet.storage.id
  network_security_group_id = azurerm_network_security_group.storage.id
}

# Proximity Placement Group for low latency
resource "azurerm_proximity_placement_group" "hpc" {
  name                = "hpc-ppg"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Azure NetApp Files Account
resource "azurerm_netapp_account" "hpc" {
  name                = "hpc-netapp-account"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Azure NetApp Files Pool
resource "azurerm_netapp_pool" "hpc" {
  name                = "hpc-netapp-pool"
  account_name        = azurerm_netapp_account.hpc.name
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  service_level       = "Ultra"
  size_in_tb          = 14
}

# Azure NetApp Files Volume
resource "azurerm_netapp_volume" "hpc" {
  name                = "hpc-netapp-volume"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  account_name        = azurerm_netapp_account.hpc.name
  pool_name           = azurerm_netapp_pool.hpc.name
  volume_path         = "hpc-data"
  service_level       = "Ultra"
  subnet_id           = azurerm_subnet.storage.id
  protocols           = ["NFSv4.1"]
  storage_quota_in_gb = 14400

  export_policy_rule {
    rule_index        = 1
    allowed_clients   = ["10.0.10.0/22"]
    protocols_enabled = ["NFSv4.1"]
    unix_read_only    = false
    unix_read_write   = true
  }
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "hpc" {
  name                = "hpc-managed-identity"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Virtual Machine Scale Set for HPC instances
resource "azurerm_linux_virtual_machine_scale_set" "hpc" {
  name                = "hpc-vmss"
  resource_group_name = azurerm_resource_group.hpc.name
  location            = azurerm_resource_group.hpc.location
  sku                 = "Standard_HB120rs_v3" # HPC-optimized instance
  instances           = 8
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Replace with your SSH key path
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS-HPC"
    sku       = "7_9"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Premium_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "primary"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.compute.id
    }
  }

  proximity_placement_group_id = azurerm_proximity_placement_group.hpc.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.hpc.id]
  }

  custom_data = base64encode(templatefile("${path.module}/user-data.sh", {
    netapp_mount_point = azurerm_netapp_volume.hpc.mount_ip_addresses[0]
    netapp_path        = azurerm_netapp_volume.hpc.volume_path
  }))

  tags = {
    Environment = "dev"
    Project     = "basic-training"
    Owner       = "ML Team"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Basic Training Cluster"
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "hpc" {
  name                = "hpc-app-insights"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  application_type    = "web"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "hpc" {
  name                = "hpc-log-analytics"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.hpc.name
}

output "virtual_network_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.hpc.name
}

output "compute_subnet_id" {
  description = "ID of the compute subnet"
  value       = azurerm_subnet.compute.id
}

output "netapp_mount_command" {
  description = "Azure NetApp Files mount command"
  value       = "sudo mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=4.1 ${azurerm_netapp_volume.hpc.mount_ip_addresses[0]}:/${azurerm_netapp_volume.hpc.volume_path} /mnt/netapp"
}

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.hpc.name
}

output "proximity_placement_group_id" {
  description = "ID of the proximity placement group"
  value       = azurerm_proximity_placement_group.hpc.id
}

output "application_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.hpc.instrumentation_key
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.hpc.id
} 