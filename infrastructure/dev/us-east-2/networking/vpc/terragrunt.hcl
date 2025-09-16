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
  cidr = local.networking.vpc_cidr
  
  azs             = local.availability_zones
  private_subnets = local.networking.subnet_cidrs.private
  public_subnets  = local.networking.subnet_cidrs.public
  
  # Additional subnets for HPC
  database_subnets = local.networking.subnet_cidrs.storage
  compute_subnets  = local.networking.subnet_cidrs.compute
  
  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true
  
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
  tags = {
    Name = "hpc-${local.environment}-vpc"
    Type = "VPC"
    Environment = local.environment
    Region = local.region
  }
  
  # Subnet tags
  private_subnet_tags = {
    Type = "Private-Subnet"
    Tier = "Compute"
    Environment = local.environment
    Region = local.region
  }
  
  public_subnet_tags = {
    Type = "Public-Subnet"
    Tier = "Management"
    Environment = local.environment
    Region = local.region
  }
  
  database_subnet_tags = {
    Type = "Database-Subnet"
    Tier = "Storage"
    Environment = local.environment
    Region = local.region
  }
  
  compute_subnet_tags = {
    Type = "Compute-Subnet"
    Tier = "HPC-Compute"
    Environment = local.environment
    Region = local.region
  }
  
  # Additional variables for local Terraform resources
  environment = local.environment
  region      = local.region
  vpc_cidr    = local.networking.vpc_cidr
  common_tags = {
    Environment = local.environment
    Region = local.region
  }
}

