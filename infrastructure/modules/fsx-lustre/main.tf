# FSx Lustre Module for HPC Infrastructure
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# FSx Lustre File System
resource "aws_fsx_lustre_file_system" "main" {
  storage_capacity                = var.storage_capacity
  storage_type                   = var.storage_type
  deployment_type                = var.deployment_type
  per_unit_storage_throughput    = var.per_unit_storage_throughput
  data_compression_type          = var.data_compression_type
  auto_import_policy             = var.auto_import_policy
  automatic_backup_retention_days = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  weekly_maintenance_start_time  = var.weekly_maintenance_start_time

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids

  tags = merge(var.common_tags, var.tags, {
    Name = var.name
  })
}

# Data repository association
resource "aws_fsx_data_repository_association" "main" {
  count = var.data_repository_path != null ? 1 : 0

  file_system_id       = aws_fsx_lustre_file_system.main.id
  data_repository_path = var.data_repository_path
  file_system_path     = var.file_system_path

  tags = merge(var.common_tags, var.tags, {
    Name = "${var.name}-data-repo"
  })
}
