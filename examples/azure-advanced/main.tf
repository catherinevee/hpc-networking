# Advanced Azure HPC Networking Example
# Auto-scaling cluster with advanced monitoring and security features

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
  name     = "hpc-networking-advanced-rg"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "hpc" {
  name                = "hpc-advanced-vnet"
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

# Network Security Groups
resource "azurerm_network_security_group" "compute" {
  name                = "compute-advanced-nsg"
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

  security_rule {
    name                       = "MPI"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1024-65535"
    source_address_prefix      = "10.0.10.0/22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "storage" {
  name                = "storage-advanced-nsg"
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

# Proximity Placement Group
resource "azurerm_proximity_placement_group" "hpc" {
  name                = "hpc-advanced-ppg"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Key Vault for secrets management
resource "azurerm_key_vault" "hpc" {
  name                        = "hpc-key-vault-${random_string.suffix.result}"
  location                    = azurerm_resource_group.hpc.location
  resource_group_name         = azurerm_resource_group.hpc.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                   = "standard"
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Data source for current Azure client
data "azurerm_client_config" "current" {}

# Key Vault Access Policy
resource "azurerm_key_vault_access_policy" "hpc" {
  key_vault_id = azurerm_key_vault.hpc.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "Purge"
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Restore", "Recover", "Purge"
  ]

  certificate_permissions = [
    "Get", "List", "Create", "Delete", "Update", "Import", "Backup", "Restore", "Recover", "Purge"
  ]
}

# Azure NetApp Files Account
resource "azurerm_netapp_account" "hpc" {
  name                = "hpc-advanced-netapp-account"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Azure NetApp Files Pool
resource "azurerm_netapp_pool" "hpc" {
  name                = "hpc-advanced-netapp-pool"
  account_name        = azurerm_netapp_account.hpc.name
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  service_level       = "Ultra"
  size_in_tb          = 28
}

# Azure NetApp Files Volume
resource "azurerm_netapp_volume" "hpc" {
  name                = "hpc-advanced-netapp-volume"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  account_name        = azurerm_netapp_account.hpc.name
  pool_name           = azurerm_netapp_pool.hpc.name
  volume_path         = "hpc-advanced-data"
  service_level       = "Ultra"
  subnet_id           = azurerm_subnet.storage.id
  protocols           = ["NFSv4.1"]
  storage_quota_in_gb = 28800

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
  name                = "hpc-advanced-managed-identity"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
}

# Key Vault Access Policy for Managed Identity
resource "azurerm_key_vault_access_policy" "managed_identity" {
  key_vault_id = azurerm_key_vault.hpc.id
  tenant_id    = azurerm_user_assigned_identity.hpc.tenant_id
  object_id    = azurerm_user_assigned_identity.hpc.principal_id

  secret_permissions = [
    "Get", "List"
  ]
}

# Application Insights
resource "azurerm_application_insights" "hpc" {
  name                = "hpc-advanced-app-insights"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  application_type    = "web"
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "hpc" {
  name                = "hpc-advanced-log-analytics"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  sku                 = "PerGB2018"
  retention_in_days   = 90
}

# Action Group for alerts
resource "azurerm_monitor_action_group" "hpc" {
  name                = "hpc-action-group"
  resource_group_name = azurerm_resource_group.hpc.name
  short_name          = "hpc-alerts"
}

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "hpc" {
  name                = "hpc-advanced-vmss"
  resource_group_name = azurerm_resource_group.hpc.name
  location            = azurerm_resource_group.hpc.location
  sku                 = "Standard_HB120rs_v3"
  instances           = 8
  admin_username      = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
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
    disk_size_gb         = 100
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

  custom_data = base64encode(templatefile("${path.module}/user-data-advanced.sh", {
    netapp_mount_point = azurerm_netapp_volume.hpc.mount_ip_addresses[0]
    netapp_path        = azurerm_netapp_volume.hpc.volume_path
    key_vault_name     = azurerm_key_vault.hpc.name
    app_insights_key   = azurerm_application_insights.hpc.instrumentation_key
    log_analytics_id   = azurerm_log_analytics_workspace.hpc.workspace_id
  }))

  tags = {
    Environment = "prod"
    Project     = "advanced-training"
    Owner       = "AI-Research"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Advanced Training Cluster"
    AutoScaling = "enabled"
  }
}

# Auto Scaling Rules
resource "azurerm_monitor_autoscale_setting" "hpc" {
  name                = "hpc-autoscale"
  resource_group_name = azurerm_resource_group.hpc.name
  location            = azurerm_resource_group.hpc.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.hpc.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 8
      minimum = 2
      maximum = 16
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.hpc.id
        time_grain        = "PT1M"
        statistic         = "Average"
        time_window       = "PT10M"
        time_aggregation  = "Average"
        operator          = "GreaterThan"
        threshold         = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.hpc.id
        time_grain        = "PT1M"
        statistic         = "Average"
        time_window       = "PT10M"
        time_aggregation  = "Average"
        operator          = "LessThan"
        threshold         = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }
}

# Metric Alerts
resource "azurerm_monitor_metric_alert" "high_cpu" {
  name                = "hpc-high-cpu-alert"
  resource_group_name = azurerm_resource_group.hpc.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.hpc.id]
  description         = "Alert when CPU usage is high"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.hpc.id
  }
}

resource "azurerm_monitor_metric_alert" "low_cpu" {
  name                = "hpc-low-cpu-alert"
  resource_group_name = azurerm_resource_group.hpc.name
  scopes              = [azurerm_linux_virtual_machine_scale_set.hpc.id]
  description         = "Alert when CPU usage is low"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachineScaleSets"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 20
  }

  action {
    action_group_id = azurerm_monitor_action_group.hpc.id
  }
}

# Private Endpoints for cost optimization
resource "azurerm_private_endpoint" "storage" {
  name                = "storage-private-endpoint"
  location            = azurerm_resource_group.hpc.location
  resource_group_name = azurerm_resource_group.hpc.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "storage-private-connection"
    private_connection_resource_id = azurerm_storage_account.hpc.id
    is_manual_connection           = false
    subresource_names             = ["blob"]
  }
}

# Storage Account for logs and data
resource "azurerm_storage_account" "hpc" {
  name                     = "hpcstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.hpc.name
  location                 = azurerm_resource_group.hpc.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
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

output "vmss_name" {
  description = "Name of the VM Scale Set"
  value       = azurerm_linux_virtual_machine_scale_set.hpc.name
}

output "netapp_mount_command" {
  description = "Azure NetApp Files mount command"
  value       = "sudo mount -t nfs -o rw,hard,rsize=65536,wsize=65536,vers=4.1 ${azurerm_netapp_volume.hpc.mount_ip_addresses[0]}:/${azurerm_netapp_volume.hpc.volume_path} /mnt/netapp"
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.hpc.name
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

output "autoscale_setting_name" {
  description = "Name of the autoscale setting"
  value       = azurerm_monitor_autoscale_setting.hpc.name
}

output "proximity_placement_group_id" {
  description = "ID of the proximity placement group"
  value       = azurerm_proximity_placement_group.hpc.id
} 