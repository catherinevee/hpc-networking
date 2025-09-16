# S3 Data Repository for Dev Environment
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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-s3-bucket.git?ref=v4.1.2"
}

# Dependencies
dependency "kms" {
  config_path = "../../networking/efa-sg"
}

inputs = {
  # Bucket Configuration
  bucket = local.storage.s3.data_repository_bucket
  
  # Versioning
  versioning = {
    enabled = true
  }
  
  # Encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
  
  # Lifecycle rules
  lifecycle_rule = [
    {
      id      = "transition_to_ia"
      enabled = true
      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        }
      ]
    }
  ]
  
  # Intelligent tiering
  intelligent_tiering = {
    enabled = true
  }
  
  # Tags
  tags = {
    Name = "hpc-${local.environment}-data-repository"
    Type = "S3-Bucket"
    Purpose = "Data-Repository"
    Environment = local.environment
    Region = local.region
  }
}