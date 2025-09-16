# VPC Configuration for Dev Environment
include "region" {
  path = "../../region.hcl"
}

terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=v5.1.2"
}

inputs = {
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
  
  # Additional VPC endpoints for HPC services
  vpc_endpoint_config = {
    ec2 = {
      service = "ec2"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ec2messages = {
      service = "ec2messages"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ssm = {
      service = "ssm"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    ssmmessages = {
      service = "ssmmessages"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    cloudwatch = {
      service = "cloudwatch"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
    cloudwatchlogs = {
      service = "logs"
      vpc_endpoint_type = "Interface"
      subnet_ids = local.networking.subnet_cidrs.private
      security_group_ids = [aws_security_group.vpc_endpoints.id]
    }
  }
  
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
}

# Security Group for VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name_prefix = "hpc-${local.environment}-vpc-endpoints-"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for VPC endpoints"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.networking.vpc_cidr]
    description = "HTTPS from VPC"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-vpc-endpoints-sg"
    Type = "VPC-Endpoints-SecurityGroup"
  })
  
  lifecycle {
    create_before_destroy = true
  }
}
