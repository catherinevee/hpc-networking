# FSx Lustre Persistent Storage for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "../../../../modules/fsx-lustre"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  skip_outputs = true
}

dependency "s3_bucket" {
  config_path = "../s3-data-repository"
  skip_outputs = true
}

inputs = {
  # FSx Lustre Configuration - Hardcoded for dev environment
  name = "hpc-dev-persistent"
  
  # Storage Configuration - Hardcoded for dev environment
  storage_capacity = 10240  # 10TB = 10240 GiB for dev
  storage_type     = "SSD"
  deployment_type  = "PERSISTENT_1"
  per_unit_storage_throughput = 1000  # MB/s per TiB
  
  # Data compression
  data_compression_type = "LZ4"
  
  # Auto import policy
  auto_import_policy = "NEW_CHANGED_DELETED"
  
  # Backup Configuration - Hardcoded for dev environment
  automatic_backup_retention_days = 30
  daily_automatic_backup_start_time = "03:00"
  weekly_maintenance_start_time = "sun:04:00"
  
  # Network Configuration
  subnet_ids         = ["subnet-placeholder"]  # Will be replaced when VPC is applied
  security_group_ids = ["sg-placeholder"]  # Will be replaced when VPC is applied

  # S3 Data Repository
  data_repository_path = "s3://hpc-dev-us-east-2-data-repository/persistent"  # Will be replaced when S3 is applied
  
  # Common tags
  common_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
  }
  
  # Tags - Hardcoded for dev environment
  tags = {
    Purpose = "Persistent-Storage"
    DataLifecycle = "Long-term"
    Name = "hpc-dev-persistent"
    Type = "FSx-Lustre"
  }
}