# VPC Configuration for Dev Environment
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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.1.2"
}

inputs = {
  # VPC Module inputs
  name = "hpc-${local.environment}-vpc"
  cidr = local.vpc_config.cidr_block
  
  azs             = local.availability_zones
  private_subnets = local.subnet_config.private.cidr_blocks
  public_subnets  = local.subnet_config.public.cidr_blocks
  
  # Additional subnets for HPC
  database_subnets = local.subnet_config.storage.cidr_blocks
  compute_subnets  = local.subnet_config.compute.cidr_blocks
  
  # Enable DNS
  enable_dns_hostnames = local.vpc_config.enable_dns_hostnames
  enable_dns_support   = local.vpc_config.enable_dns_support
  
  # Enable NAT Gateway (single for dev)
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
  
  # Enable VPC Flow Logs
  enable_flow_log = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 60
  
  # VPC Endpoints for AWS services
  enable_s3_endpoint = true
  
  # Tags
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-vpc"
    Type = "VPC"
  })
  
  # Subnet tags
  private_subnet_tags = merge(local.common_tags, {
    Type = "Private-Subnet"
    Tier = "Compute"
  })
  
  public_subnet_tags = merge(local.common_tags, {
    Type = "Public-Subnet"
    Tier = "Management"
  })
  
  database_subnet_tags = merge(local.common_tags, {
    Type = "Database-Subnet"
    Tier = "Storage"
  })
  
  compute_subnet_tags = merge(local.common_tags, {
    Type = "Compute-Subnet"
    Tier = "HPC-Compute"
  })
  
  # Additional variables for local Terraform resources
  environment = local.environment
  region      = local.region
  vpc_cidr    = local.vpc_config.cidr_block
  common_tags = local.common_tags
}

