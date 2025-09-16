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
}

dependency "s3_bucket" {
  config_path = "../s3-data-repository"
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
  subnet_ids         = dependency.vpc.outputs.database_subnets
  security_group_ids = [dependency.vpc.outputs.vpc_endpoints_security_group_id]
  
  # S3 Data Repository
  data_repository_path = "s3://${dependency.s3_bucket.outputs.s3_bucket_id}/scratch"
  
  # Tags
  tags = merge(local.common_tags, local.fsx_lustre_config.scratch.tags, {
    Name = "hpc-${local.environment}-scratch"
    Type = "FSx-Lustre"
  })
}