# Root terragrunt.hcl file for HPC Networking Terragrunt example
# This file provides common configuration for all Terragrunt configurations

# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  
  config = {
    bucket         = "hpc-networking-terraform-state"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "hpc-networking-terraform-locks"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Configure Terragrunt to use the latest version
terraform_version_constraint = "1.12.2"

# Configure Terragrunt to use the latest AWS provider
generate "versions" {
  path      = "versions.tf"
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
EOF
}

# Global inputs that apply to all configurations
inputs = {
  # Common tags for all resources
  common_tags = {
    Environment = "production"
    Project     = "hpc-networking"
    ManagedBy   = "terragrunt"
    Owner       = "ML Team"
    CostCenter  = "AI-Infrastructure"
  }
  
  # Common AWS settings
  aws_region = "us-east-1"
  
  # Common networking settings
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
  
  # Common monitoring settings
  enable_cloudwatch = true
  cloudwatch_retention_days = 90
} 