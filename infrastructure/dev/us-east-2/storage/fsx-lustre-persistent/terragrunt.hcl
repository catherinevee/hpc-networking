# FSx Lustre Persistent Storage for Dev Environment
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
  storage_type = "SSD"
  deployment_type = "PERSISTENT_1"
  per_unit_storage_throughput = local.storage.fsx_lustre.persistent.per_unit_storage_throughput
  
  # Compression
  data_compression_type = "LZ4"
  
  # Auto Import Policy
  auto_import_policy = "NEW_CHANGED_DELETED"
  
  # Backup Configuration
  automatic_backup_retention_days = 30
  daily_automatic_backup_start_time = "03:00"
  weekly_maintenance_start_time = "sun:04:00"
  
  # Network Configuration
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.compute_subnets
  security_group_ids = [aws_security_group.fsx_persistent.id]
  
  # S3 Data Repository
  data_repository_configuration = {
    auto_export_policy = {
      events = ["NEW", "CHANGED", "DELETED"]
    }
    auto_import_policy = {
      events = ["NEW", "CHANGED", "DELETED"]
    }
    s3 = {
      auto_export_policy = {
        events = ["NEW", "CHANGED", "DELETED"]
      }
      auto_import_policy = {
        events = ["NEW", "CHANGED", "DELETED"]
      }
    }
  }
  
  # S3 Bucket for Data Repository
  data_repository_path = "s3://${dependency.s3_bucket.outputs.bucket_name}/persistent"
  
  # Encryption
  kms_key_id = aws_kms_key.hpc.arn
  
  # Tags
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-persistent"
    Type = "FSx-Lustre"
    Purpose = "Persistent-Storage"
    DataLifecycle = "Long-term"
  })
}

# Security Group for FSx Lustre
resource "aws_security_group" "fsx_persistent" {
  name_prefix = "hpc-${local.environment}-fsx-persistent-"
  vpc_id      = dependency.vpc.outputs.vpc_id
  description = "Security group for FSx Lustre persistent storage"
  
  # NFS access
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [local.networking.vpc_cidr]
    description = "NFS access"
  }
  
  # RPC portmapper
  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = [local.networking.vpc_cidr]
    description = "RPC portmapper"
  }
  
  # Lustre MGS
  ingress {
    from_port   = 20048
    to_port     = 20048
    protocol    = "tcp"
    cidr_blocks = [local.networking.vpc_cidr]
    description = "Lustre MGS"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-fsx-persistent-sg"
    Type = "FSx-SecurityGroup"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}

# KMS Key for encryption
resource "aws_kms_key" "hpc" {
  description             = "HPC KMS key for ${local.environment}"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-kms-key"
    Type = "KMS-Key"
  })
}

resource "aws_kms_alias" "hpc" {
  name          = "alias/hpc-${local.environment}"
  target_key_id = aws_kms_key.hpc.key_id
}
