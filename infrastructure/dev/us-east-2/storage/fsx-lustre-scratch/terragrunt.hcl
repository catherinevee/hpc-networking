# FSx Lustre Scratch Storage for Dev Environment
include "account" {
  path = find_in_parent_folders("account.hcl")
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
  skip_outputs = true
}

dependency "s3_bucket" {
  config_path = "../s3-data-repository"
  skip_outputs = true
}

inputs = {
  # FSx Lustre Configuration
  name = "hpc-${local.environment}-scratch"
  
  # Storage Configuration
  storage_capacity = local.fsx_lustre_config.scratch.storage_capacity
  storage_type     = local.fsx_lustre_config.scratch.storage_type
  deployment_type  = local.fsx_lustre_config.scratch.deployment_type
  per_unit_storage_throughput = local.fsx_lustre_config.scratch.per_unit_storage_throughput
  
  # Data compression
  data_compression_type = local.fsx_lustre_config.scratch.data_compression_type
  
  # Auto import policy
  auto_import_policy = local.fsx_lustre_config.scratch.auto_import_policy
  
  # Backup Configuration
  automatic_backup_retention_days = local.fsx_lustre_config.scratch.automatic_backup_retention_days
  daily_automatic_backup_start_time = local.fsx_lustre_config.scratch.daily_automatic_backup_start_time
  weekly_maintenance_start_time = local.fsx_lustre_config.scratch.weekly_maintenance_start_time
  
  # Network Configuration
  subnet_ids         = ["subnet-placeholder"]  # Will be replaced when VPC is applied
  security_group_ids = ["sg-placeholder"]  # Will be replaced when VPC is applied

  # S3 Data Repository
  data_repository_path = "s3://hpc-dev-data-repository/scratch"  # Will be replaced when S3 is applied
  
  # Tags
  tags = merge(local.common_tags, local.fsx_lustre_config.scratch.tags, {
    Name = "hpc-${local.environment}-scratch"
    Type = "FSx-Lustre"
  })
}