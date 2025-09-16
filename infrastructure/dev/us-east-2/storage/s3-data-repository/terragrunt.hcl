# S3 Data Repository for Dev Environment
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
  
  # Lifecycle Rules
  lifecycle_rule = [
    {
      id = "transition_to_ia"
      enabled = true
      transition = [
        {
          days = 30
          storage_class = "STANDARD_IA"
        }
      ]
    },
    {
      id = "transition_to_glacier"
      enabled = true
      transition = [
        {
          days = 90
          storage_class = "GLACIER"
        }
      ]
    },
    {
      id = "transition_to_deep_archive"
      enabled = true
      transition = [
        {
          days = 365
          storage_class = "DEEP_ARCHIVE"
        }
      ]
    }
  ]
  
  # Intelligent Tiering
  intelligent_tiering = {
    enabled = true
    status = "Enabled"
  }
  
  # Public Access Block
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
  
  # Bucket Policy
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AllowFSxLustreAccess"
        Effect = "Allow"
        Principal = {
          Service = "fsx.amazonaws.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.storage.s3.data_repository_bucket}",
          "arn:aws:s3:::${local.storage.s3.data_repository_bucket}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid = "AllowHPCInstancesAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/hpc-${local.environment}-*"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${local.storage.s3.data_repository_bucket}",
          "arn:aws:s3:::${local.storage.s3.data_repository_bucket}/*"
        ]
      }
    ]
  })
  
  # CORS Configuration
  cors_rule = [
    {
      allowed_headers = ["*"]
      allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
      allowed_origins = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]
  
  # Tags
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-data-repository"
    Type = "S3-Bucket"
    Purpose = "Data-Repository"
  })
}

# Random ID for bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for current account
data "aws_caller_identity" "current" {}
