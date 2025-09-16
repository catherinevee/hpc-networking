# Dev Environment Configuration
include "account" {
  path = find_in_parent_folders("account.hcl")
}

# Include shared configurations
include "hpc_cluster" {
  path = "../_envcommon/hpc-cluster.hcl"
}

include "networking" {
  path = "../_envcommon/networking.hcl"
}

include "storage" {
  path = "../_envcommon/storage.hcl"
}

include "monitoring" {
  path = "../_envcommon/monitoring.hcl"
}

# Dev-specific overrides
locals {
  # Override cluster capacity for dev
  cluster_capacity = 100
  
  # Override instance types for dev (smaller, cheaper)
  instance_types = {
    compute = "c5n.9xlarge"
    memory  = "r5n.12xlarge" 
    gpu     = "p3.8xlarge"
    debug   = "c5n.large"
  }
  
  # Override storage sizes for dev
  fsx_lustre_scratch_size = 50    # 50TB
  fsx_lustre_persistent_size = 10 # 10TB
  
  # Override monitoring for dev
  cloudwatch_log_retention_days = 7
  enable_detailed_monitoring = false
  enable_grafana = false
  
  # Override security for dev
  enable_guardduty = false
  enable_inspector = false
  enable_config = false
  
  # Override cost optimization for dev
  spot_instance_percentage = 90
  enable_savings_plans = false
  enable_reserved_instances = false
  
  # Dev-specific tags
  common_tags = {
    Environment = "dev"
    CostCenter  = "HPC-Dev"
    Owner       = "HPC-Team"
    Project     = "HPC-Networking"
    ManagedBy   = "Terragrunt"
  }
}
