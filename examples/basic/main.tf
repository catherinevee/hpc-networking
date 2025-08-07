# Basic HPC Networking Example
# Simple 8-node training cluster with EFA and FSx for Lustre

terraform {
  required_version = "1.12.2"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  id = "vpc-12345678" # Replace with your VPC ID
}

# Basic HPC Networking Module
module "hpc_networking" {
  source = "../../"

  # Required variables
  vpc_id = data.aws_vpc.existing.id
  
  # Instance configuration
  instance_type = "p5.48xlarge"
  instance_count = 8
  
  # Networking
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Storage
  enable_fsx_lustre = true
  fsx_storage_capacity = 14400 # 14.4TB
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = false
  
  # Monitoring
  enable_cloudwatch = true
  
  # Tags
  project_name = "basic-training"
  environment = "dev"
  
  tags = {
    Owner       = "ML Team"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Basic Training Cluster"
  }
}

# Outputs
output "instance_ips" {
  description = "Private IPs of HPC instances"
  value = module.hpc_networking.hpc_instances
}

output "fsx_mount_command" {
  description = "FSx for Lustre mount command"
  value = module.hpc_networking.fsx_lustre != null ? "sudo mount -t lustre ${module.hpc_networking.fsx_lustre.dns_name}@tcp:/${module.hpc_networking.fsx_lustre.mount_name} /fsx" : "FSx not enabled"
}

output "performance_metrics" {
  description = "Expected performance metrics"
  value = module.hpc_networking.network_performance_metrics
} 