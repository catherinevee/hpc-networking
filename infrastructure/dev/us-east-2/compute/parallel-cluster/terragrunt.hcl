# AWS ParallelCluster Configuration for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "../../../../modules/parallel-cluster"
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
  create_cluster = true

  # Head Node Configuration
  head_node_instance_type = "c5n.2xlarge"

  # Network Configuration
  subnet_id = "subnet-placeholder"  # Will be replaced when VPC is applied
  security_group_ids = ["sg-placeholder"]  # Will be replaced when EFA-SG is applied

  # Common tags
  common_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
  }

  # Tags - Hardcoded for dev environment
  tags = {
    Name = "hpc-dev"
    Type = "ParallelCluster"
    Purpose = "HPC-Compute"
  }
}