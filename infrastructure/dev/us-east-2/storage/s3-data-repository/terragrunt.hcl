# S3 Data Repository for Dev Environment
include "account" {
  path = find_in_parent_folders("account.hcl")
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
  bucket = local.s3_config.data_repository.bucket_name
  
  # Versioning
  versioning = {
    enabled = local.s3_config.data_repository.versioning_enabled
  }
  
  # Encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = local.s3_config.data_repository.encryption_algorithm
      }
    }
  }
  
  # Lifecycle rules
  lifecycle_rule = local.s3_config.data_repository.lifecycle_rules
  
  # Intelligent tiering
  intelligent_tiering = local.s3_config.data_repository.intelligent_tiering
  
  # Tags
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-data-repository"
    Type = "S3-Bucket"
    Purpose = "Data-Repository"
  })
}