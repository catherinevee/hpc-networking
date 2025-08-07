# Terragrunt configuration for HPC Networking Module
# This example demonstrates using Terragrunt with the HPC networking module

# Include the root terragrunt.hcl file for common configuration
include "root" {
  path = find_in_parent_folders()
}

# Configure Terraform to use the HPC networking module
terraform {
  source = "../../"
}

# Configure AWS provider
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = "1.12.2"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.11.1"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  
  default_tags {
    tags = {
      Environment = "production"
      Project     = "hpc-networking"
      ManagedBy   = "terragrunt"
      Owner       = "ML Team"
    }
  }
}
EOF
}

# Input variables for the HPC networking module
inputs = {
  # Required variables
  vpc_id = "vpc-12345678" # Replace with your VPC ID
  
  # Instance configuration
  instance_type = "p5.48xlarge"
  instance_count = 8
  
  # Networking
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Advanced networking
  enable_jumbo_frames = true
  enable_sriov = true
  numa_optimization = true
  
  # Storage
  enable_fsx_lustre = true
  fsx_storage_capacity = 14400 # 14.4TB
  fsx_deployment_type = "PERSISTENT_2"
  
  # Auto scaling
  enable_auto_scaling = true
  min_size = 2
  max_size = 16
  desired_capacity = 8
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = false
  
  # Security
  enable_encryption = true
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
  
  # Monitoring
  enable_cloudwatch = true
  cloudwatch_retention_days = 90
  
  # Tags
  project_name = "terragrunt-hpc"
  environment = "prod"
  
  tags = {
    Owner       = "ML Team"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Terragrunt HPC Cluster"
    ManagedBy   = "terragrunt"
  }
} 