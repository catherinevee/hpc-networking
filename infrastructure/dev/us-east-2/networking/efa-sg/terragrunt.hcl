# EFA Security Group Configuration for Dev Environment
include "region" {
  path = "../../region.hcl"
}

terraform {
  source = "../../../modules/efa-network"
}

# Get VPC information from the VPC module
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  cluster_name = "hpc-${local.environment}"
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = local.networking.vpc_cidr
  subnet_id    = dependency.vpc.outputs.compute_subnets[0]
  availability_zone = local.networking.primary_az
  
  # EFA Configuration
  efa_device = "efa0"
  mtu_size   = 9000
  enable_gpudirect = false  # Disabled for dev
  
  # Instance Configuration
  instance_type = local.instance_types.compute
  ami_id        = data.aws_ami.hpc_optimized.id
  
  # EFA-specific settings
  enable_partition_strategy = false  # Single cluster for dev
  partition_count = 1
  
  # Storage Configuration
  root_volume_size = 100
  additional_ebs_volumes = [
    {
      device_name = "/dev/sdf"
      volume_type = "gp3"
      volume_size = 500
      iops        = 3000
      throughput  = 125
    }
  ]
  
  # CPU Configuration for optimal performance
  cpu_core_count = 36  # c5n.9xlarge has 36 vCPUs
  threads_per_core = 1  # Disable hyperthreading for consistent performance
  cpu_credits = "standard"
  
  # S3 Configuration
  s3_bucket_name = local.storage.s3.data_repository_bucket
  
  # Monitoring Configuration
  log_retention_days = local.monitoring.cloudwatch.log_retention_days
  kms_key_id = aws_kms_key.hpc.arn
  
  # Alarm Configuration
  alarm_actions = [aws_sns_topic.hpc_alerts.arn]
  ok_actions    = [aws_sns_topic.hpc_alerts.arn]
  
  # Tags
  tags = merge(local.common_tags, {
    Component = "EFA-Network"
    Tier      = "HPC-Compute"
  })
}

# Data source for HPC-optimized AMI
data "aws_ami" "hpc_optimized" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  
  filter {
    name   = "architecture"
    values = ["x86_64"]
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

# SNS Topic for alerts
resource "aws_sns_topic" "hpc_alerts" {
  name = "hpc-${local.environment}-alerts"
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-alerts"
    Type = "SNS-Topic"
  })
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "hpc_alerts" {
  arn = aws_sns_topic.hpc_alerts.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.hpc_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Random ID for bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for current account
data "aws_caller_identity" "current" {}
