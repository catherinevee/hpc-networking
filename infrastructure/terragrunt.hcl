# Root Terragrunt configuration for HPC Networking Infrastructure
terraform {
  source = "."
}

# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    bucket         = "hpc-networking-terraform-state-${get_aws_account_id()}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "hpc-networking-terraform-locks"
    s3_bucket_tags = {
      Owner       = "HPC-Team"
      Purpose     = "Terraform State Storage"
      Environment = "All"
    }
    dynamodb_table_tags = {
      Owner       = "HPC-Team"
      Purpose     = "Terraform State Locking"
      Environment = "All"
    }
  }
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "HPC-Networking"
      Environment = var.environment
      ManagedBy   = "Terragrunt"
      Owner       = "HPC-Team"
    }
  }
}
EOF
}

# Configure input variables
inputs = {
  aws_region = "us-east-2"
  environment = "dev"
  
  # HPC Cluster Configuration
  cluster_name = "hpc-${get_env("ENVIRONMENT", "dev")}"
  cluster_capacity = {
    dev = 100
    staging = 500
    production = 1000
  }
  
  # Network Configuration
  vpc_cidr = "10.0.0.0/16"
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  
  # EFA Configuration
  efa_enabled = true
  efa_instance_types = [
    "hpc6a.48xlarge",
    "c5n.18xlarge",
    "c5n.24xlarge",
    "c5n.9xlarge"
  ]
  
  # Storage Configuration
  fsx_lustre_scratch_size = 500  # TB
  fsx_lustre_persistent_size = 100  # TB
  s3_data_repository_bucket = "hpc-data-repository-${get_aws_account_id()}"
  
  # Monitoring Configuration
  cloudwatch_log_retention_days = 30
  enable_detailed_monitoring = true
  
  # Security Configuration
  enable_encryption = true
  enable_vpc_flow_logs = true
  enable_guardduty = true
  
  # Cost Optimization
  spot_instance_percentage = 70
  enable_savings_plans = true
  budget_limit = 200000  # USD per month
}
