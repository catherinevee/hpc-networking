# AWS ParallelCluster Configuration for Dev Environment
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
  source = "git::https://github.com/aws-ia/terraform-aws-parallelcluster.git?ref=v3.7.0"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
}

dependency "efa_sg" {
  config_path = "../../networking/efa-sg"
}

dependency "fsx_scratch" {
  config_path = "../../storage/fsx-lustre-scratch"
}

dependency "fsx_persistent" {
  config_path = "../../storage/fsx-lustre-persistent"
}

inputs = {
  # Cluster Configuration
  cluster_name = local.cluster_name
  
  # VPC Configuration
  vpc_id = dependency.vpc.outputs.vpc_id
  subnet_id = dependency.vpc.outputs.compute_subnets[0]
  
  # Security Groups
  additional_security_groups = [dependency.efa_sg.outputs.security_group_id]
  
  # Storage Configuration
  shared_storage = {
    fsx_lustre = [
      {
        name = "scratch"
        mount_dir = "/scratch"
        fsx_fs_id = dependency.fsx_scratch.outputs.fsx_lustre_file_system_id
      },
      {
        name = "persistent"
        mount_dir = "/persistent"
        fsx_fs_id = dependency.fsx_persistent.outputs.fsx_lustre_file_system_id
      }
    ]
  }
  
  # Head Node Configuration
  head_node = {
    instance_type = "c5n.2xlarge"
    ami_id = data.aws_ami.hpc_optimized.id
    root_volume = {
      size = 50
      volume_type = "gp3"
    }
  }
  
  # Compute Nodes Configuration
  compute_nodes = {
    instance_types = local.slurm_queues.compute.instance_types
    min_count = local.slurm_queues.compute.min_count
    max_count = local.slurm_queues.compute.max_count
    spot_percentage = local.slurm_queues.compute.spot_percentage
  }
  
  # EFA Configuration
  efa = {
    enabled = true
    gdr_support = false  # Disabled for dev
  }
  
  # Tags
  tags = {
    Name = local.cluster_name
    Type = "ParallelCluster"
    Purpose = "HPC-Compute"
    Environment = local.environment
    Region = local.region
  }
  
  # Additional variables for local Terraform resources
  environment = local.environment
  region      = local.region
  common_tags = {
    Environment = local.environment
    Region = local.region
  }
}