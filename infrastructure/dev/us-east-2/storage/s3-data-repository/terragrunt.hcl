# S3 Data Repository for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "../../../../modules/s3-bucket"
}

# Dependencies
dependency "kms" {
  config_path = "../../networking/efa-sg"
  skip_outputs = true
}

inputs = {
  # Bucket Configuration - Hardcoded for dev environment
  bucket = "hpc-dev-us-east-2-data-repository"
  
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
  
  # Lifecycle rules - Hardcoded for dev environment
  lifecycle_rule = [
    {
      id = "archive-old-versions"
      enabled = true
      noncurrent_version_transitions = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 60
          storage_class = "GLACIER"
        },
      ]
      noncurrent_version_expiration = {
        days = 365
      }
    }
  ]
  
  # Intelligent tiering - Disabled for dev
  intelligent_tiering = false
  
  # Tags - Hardcoded for dev environment
  tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Name = "hpc-dev-data-repository"
    Type = "S3-Bucket"
    Purpose = "Data-Repository"
  }
}