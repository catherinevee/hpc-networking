# EFA Security Group Configuration for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "../../../modules/efa-network"
}

# Get VPC information from the VPC module
dependency "vpc" {
  config_path = "../vpc"
  skip_outputs = true
}

inputs = {
  cluster_name = "hpc-dev"
  vpc_id       = "vpc-placeholder"  # Will be replaced when VPC is applied
  vpc_cidr     = "10.0.0.0/16"
  subnet_id    = "subnet-placeholder"  # Will be replaced when VPC is applied
  availability_zone = "us-east-2a"
  
  # EFA Configuration - Hardcoded for dev environment
  efa_device = "efa0"
  mtu_size   = 9000
  enable_gpudirect = false
  
  # Instance Configuration - Hardcoded for dev environment
  instance_type = "c5n.9xlarge"
  ami_id        = "ami-placeholder"  # Will be resolved by data source
  
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
  
  # S3 Configuration - Hardcoded for dev environment
  s3_bucket_name = "hpc-dev-us-east-2-data-repository"
  
  # Monitoring Configuration - Hardcoded for dev environment
  log_retention_days = 7
  kms_key_id = "arn:aws:kms:us-east-2:025066254478:key/placeholder"  # Will be replaced when KMS is applied
  
  # Alarm Configuration
  alarm_actions = ["arn:aws:sns:us-east-2:025066254478:placeholder"]  # Will be replaced when SNS is applied
  ok_actions    = ["arn:aws:sns:us-east-2:025066254478:placeholder"]  # Will be replaced when SNS is applied
  
  # Tags - Hardcoded for dev environment
  tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Component = "EFA-Network"
    Tier = "HPC-Compute"
  }
  
  # Additional variables for local Terraform resources
  environment = "dev"
  region      = "us-east-2"
  common_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
  }
}