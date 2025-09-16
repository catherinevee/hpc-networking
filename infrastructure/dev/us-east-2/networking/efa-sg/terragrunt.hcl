# EFA Security Group Configuration for Dev Environment
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
  source = "../../../modules/efa-network"
}

# Get VPC information from the VPC module
dependency "vpc" {
  config_path = "../vpc"
}

inputs = {
  cluster_name = "hpc-${local.environment}"
  vpc_id       = dependency.vpc.outputs.vpc_id
  vpc_cidr     = local.vpc_config.cidr_block
  subnet_id    = dependency.vpc.outputs.compute_subnets[0]
  availability_zone = local.subnet_config.compute.availability_zones[0]
  
  # EFA Configuration
  efa_device = "efa0"
  mtu_size   = 9000
  enable_gpudirect = false  # Disabled for dev
  
  # Instance Configuration
  instance_type = local.instance_types.compute.hpc_optimized
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
  s3_bucket_name = local.s3_config.data_repository.bucket_name
  
  # Monitoring Configuration
  log_retention_days = local.cloudwatch_config.log_groups.hpc_system_logs.retention_in_days
  kms_key_id = aws_kms_key.hpc.arn
  
  # Alarm Configuration
  alarm_actions = [aws_sns_topic.hpc_alerts.arn]
  ok_actions    = [aws_sns_topic.hpc_alerts.arn]
  
  # Tags
  tags = merge(local.common_tags, {
    Component = "EFA-Network"
    Tier      = "HPC-Compute"
  })
  
  # Additional variables for local Terraform resources
  environment = local.environment
  region      = local.region
  common_tags = local.common_tags
}