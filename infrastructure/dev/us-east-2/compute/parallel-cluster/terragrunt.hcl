# AWS ParallelCluster Configuration for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "git::https://github.com/aws-ia/terraform-aws-parallelcluster.git?ref=v3.7.0"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
  skip_outputs = true
}

dependency "efa_sg" {
  config_path = "../../networking/efa-sg"
  skip_outputs = true
}

dependency "fsx_scratch" {
  config_path = "../../storage/fsx-lustre-scratch"
  skip_outputs = true
}

dependency "fsx_persistent" {
  config_path = "../../storage/fsx-lustre-persistent"
  skip_outputs = true
}

inputs = {
  # Cluster Configuration - Hardcoded for dev environment
  cluster_name = "hpc-dev"
  
  # VPC Configuration
  vpc_id = "vpc-placeholder"  # Will be replaced when VPC is applied
  subnet_id = "subnet-placeholder"  # Will be replaced when VPC is applied

  # Security Groups
  additional_security_groups = ["sg-placeholder"]  # Will be replaced when EFA-SG is applied

  # Storage Configuration
  shared_storage = {
    fsx_lustre = [
      {
        name = "scratch"
        mount_dir = "/scratch"
        fsx_fs_id = "fsx-placeholder"  # Will be replaced when FSx is applied
      },
      {
        name = "persistent"
        mount_dir = "/persistent"
        fsx_fs_id = "fsx-placeholder"  # Will be replaced when FSx is applied
      }
    ]
  }
  
  # Head Node Configuration
  head_node = {
    instance_type = "c5n.2xlarge"
    ami_id = "ami-placeholder"  # Will be resolved by data source
    root_volume = {
      size = 50
      volume_type = "gp3"
    }
  }
  
  # Compute Nodes Configuration - Hardcoded for dev environment
  compute_nodes = {
    instance_types = ["c5n.9xlarge", "c5n.18xlarge"]
    min_count = 0
    max_count = 500
    spot_percentage = 70
  }
  
  # EFA Configuration - Hardcoded for dev environment
  efa = {
    enabled = true
    gdr_support = false
  }
  
  # Tags - Hardcoded for dev environment
  tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Name = "hpc-dev"
    Type = "ParallelCluster"
    Purpose = "HPC-Compute"
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