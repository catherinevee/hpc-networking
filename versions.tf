terraform {
  required_version = ">= 1.12.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.67.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.108.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6.3"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.11.1"
    }
  }

  # Performance optimizations for large deployments
  # Uncomment for deployments with >1000 resources
  # parallelism = 20
}

# Provider configuration with optimizations
provider "aws" {
  region = var.region
  
  default_tags {
    tags = local.common_tags
  }
  
  # Optimize for large deployments
  max_retries = 3
  retry_mode  = "adaptive"
  
  # Assume role for cross-account access (if needed)
  # assume_role {
  #   role_arn = var.assume_role_arn
  # }
} 