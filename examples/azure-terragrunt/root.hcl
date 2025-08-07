# Root Terragrunt Configuration for Azure HPC Networking
# Provides remote state management and global provider configuration

# Remote state configuration
remote_state {
  backend = "azurerm"
  
  config = {
    resource_group_name  = "hpc-terragrunt-state-rg"
    storage_account_name = "hpcterraformstate"
    container_name       = "terraform-state"
    key                  = "${path_relative_to_include()}/terraform.tfstate"
  }
  
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Global provider configuration
generate "providers" {
  path      = "providers.tf"
  if_exists = "overwrite_terragrunt"
  
  contents = <<EOF
terraform {
  required_version = "1.12.2"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.95.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  
  # Default tags for all resources
  default_tags {
    tags = {
      Environment = "prod"
      Project     = "hpc-networking"
      Owner       = "AI-Research"
      CostCenter  = "AI-Infrastructure"
      ManagedBy   = "terragrunt"
    }
  }
}
EOF
}

# Global inputs
inputs = {
  # Common configuration
  location = "East US"
  
  # Network configuration
  address_space = ["10.0.0.0/16"]
  
  # Security configuration
  enable_encryption = true
  
  # Monitoring configuration
  enable_application_insights = true
  enable_log_analytics = true
  log_retention_days = 90
  
  # Performance configuration
  enable_proximity_placement_group = true
  enable_managed_identity = true
  
  # Cost optimization
  enable_private_endpoints = true
} 