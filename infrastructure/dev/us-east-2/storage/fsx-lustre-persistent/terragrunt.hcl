# FSx Lustre Persistent Storage for Dev Environment
include "account" {
  path = find_in_parent_folders("account.hcl")
}

include "env" {
  path = "../../../env.hcl"
}

include "region" {
  path = "../../region.hcl"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-fsx-lustre.git?ref=v1.0.0"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
}

dependency "s3_bucket" {
  config_path = "../s3-data-repository"
}

inputs = {
  # FSx Lustre Configuration
  name = "hpc-${local.environment}-persistent"
  
  # Storage Configuration
  storage_capacity = local.storage.fsx_lustre.persistent.storage_capacity
  storage_type     = "SSD"
  deployment_type  = "PERSISTENT_1"
  per_unit_storage_throughput = local.storage.fsx_lustre.persistent.per_unit_storage_throughput
  
  # Data compression
  data_compression_type = "LZ4"
  
  # Auto import policy
  auto_import_policy = "NEW_CHANGED"
  
  # Backup Configuration
  automatic_backup_retention_days = 7  # 7 days backup for persistent
  daily_automatic_backup_start_time = "03:00"
  weekly_maintenance_start_time = "1:00:00"
  
  # Network Configuration
  subnet_ids         = dependency.vpc.outputs.database_subnets
  security_group_ids = [dependency.vpc.outputs.vpc_endpoints_security_group_id]
  
  # S3 Data Repository
  data_repository_path = "s3://${dependency.s3_bucket.outputs.s3_bucket_id}/persistent"
  
  # Tags
  tags = {
    Name = "hpc-${local.environment}-persistent"
    Type = "FSx-Lustre"
    Purpose = "Persistent-Storage"
    Environment = local.environment
    Region = local.region
  }
}