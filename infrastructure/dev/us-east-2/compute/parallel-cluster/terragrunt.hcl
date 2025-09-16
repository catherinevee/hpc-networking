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
  # Cluster Configuration
  cluster_name = local.cluster_name
  
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
    enabled = local.efa_config.enabled
    gdr_support = local.efa_config.enable_gpudirect
  }
  
  # Tags
  tags = merge(local.common_tags, {
    Name = local.cluster_name
    Type = "ParallelCluster"
    Purpose = "HPC-Compute"
  })
  
  # Additional variables for local Terraform resources
  environment = local.environment
  region      = local.region
  common_tags = local.common_tags
}