# VPC Configuration for Dev Environment
include "account" {
  path = find_in_parent_folders("account.hcl")
}


include "region" {
  path = "../../region.hcl"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.1.2"
}

inputs = {
  # VPC Module inputs
  name = "hpc-dev-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-2a", "us-east-2b", "us-east-2c"]
  private_subnets = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  
  # Additional subnets for HPC
  database_subnets = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]
  compute_subnets  = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]

  # Enable DNS
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  # Enable NAT Gateway (single for dev)
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
  
  # Disable VPC Flow Logs for now to simplify configuration
  enable_flow_log = false
  
  # VPC Endpoints for AWS services
  enable_s3_endpoint = true
  
  # Tags
  tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Name = "hpc-dev-vpc"
    Type = "VPC"
  }

  # Subnet tags
  private_subnet_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Type = "Private-Subnet"
    Tier = "Compute"
  }

  public_subnet_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Type = "Public-Subnet"
    Tier = "Management"
  }

  database_subnet_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Type = "Database-Subnet"
    Tier = "Storage"
  }

  compute_subnet_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Type = "Compute-Subnet"
    Tier = "HPC-Compute"
  }
  
  # Additional variables for local Terraform resources
  environment = "dev"
  region      = "us-east-2"
  vpc_cidr    = "10.0.0.0/16"
  common_tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
  }
}

