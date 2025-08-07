# Azure HPC Networking Terragrunt Configuration
# Advanced auto-scaling cluster with comprehensive monitoring

include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "../../"
}

# Inputs for Azure HPC Networking
inputs = {
  # Resource Group Configuration
  resource_group_name = "hpc-networking-terragrunt-rg"
  location            = "East US"
  
  # Virtual Network Configuration
  virtual_network_name = "hpc-terragrunt-vnet"
  address_space        = ["10.0.0.0/16"]
  
  # Subnet Configuration
  compute_subnet_cidr = "10.0.10.0/22"
  storage_subnet_cidr = "10.0.20.0/24"
  endpoints_subnet_cidr = "10.0.30.0/24"
  
  # VM Scale Set Configuration
  vmss_name = "hpc-terragrunt-vmss"
  vm_sku    = "Standard_HB120rs_v3" # HPC-optimized instance
  instances = 8
  
  # Auto Scaling Configuration
  enable_autoscaling = true
  min_size          = 2
  max_size          = 16
  desired_capacity  = 8
  
  # Auto Scaling Rules
  scale_up_threshold   = 70
  scale_down_threshold = 30
  scale_cooldown       = "PT5M"
  
  # Storage Configuration
  enable_netapp_files = true
  netapp_storage_tb   = 28
  netapp_volume_gb    = 28800
  
  # Security Configuration
  enable_key_vault = true
  enable_encryption = true
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
  
  # Monitoring Configuration
  enable_application_insights = true
  enable_log_analytics = true
  log_retention_days = 90
  
  # Performance Configuration
  enable_proximity_placement_group = true
  enable_managed_identity = true
  
  # Cost Optimization
  enable_private_endpoints = true
  enable_spot_instances = false
  
  # Tags
  tags = {
    Environment = "prod"
    Project     = "terragrunt-training"
    Owner       = "AI-Research"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Terragrunt Training Cluster"
    AutoScaling = "enabled"
    ManagedBy   = "terragrunt"
  }
} 