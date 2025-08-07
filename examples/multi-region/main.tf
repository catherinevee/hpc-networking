# Multi-Region HPC Networking Example
# Distributed training across multiple AWS regions

terraform {
  required_version = "1.12.2"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
      configuration_aliases = [aws.us_east_1, aws.us_west_2]
    }
  }
}

# Primary Region (us-east-1) - P5 instances
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Secondary Region (us-west-2) - P4d instances
provider "aws" {
  alias  = "us_west_2"
  region = "us-west-2"
}

# Data sources for existing VPCs
data "aws_vpc" "primary" {
  provider = aws.us_east_1
  id       = "vpc-primary-east" # Replace with your VPC ID
}

data "aws_vpc" "secondary" {
  provider = aws.us_west_2
  id       = "vpc-secondary-west" # Replace with your VPC ID
}

# Primary Region HPC Cluster (P5 instances)
module "hpc_primary" {
  source = "../../"
  providers = {
    aws = aws.us_east_1
  }

  # Required variables
  vpc_id = data.aws_vpc.primary.id
  
  # Instance configuration
  instance_type = "p5.48xlarge"
  instance_count = 8
  
  # Networking
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Storage
  enable_fsx_lustre = true
  fsx_storage_capacity = 14400 # 14.4TB
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = false
  
  # Monitoring
  enable_cloudwatch = true
  
  # Tags
  project_name = "multi-region-primary"
  environment = "prod"
  
  tags = {
    Region      = "us-east-1"
    Purpose     = "Primary Training Cluster"
    Owner       = "AI-Research"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
  }
}

# Secondary Region HPC Cluster (P4d instances)
module "hpc_secondary" {
  source = "../../"
  providers = {
    aws = aws.us_west_2
  }

  # Required variables
  vpc_id = data.aws_vpc.secondary.id
  
  # Instance configuration
  instance_type = "p4d.24xlarge"
  instance_count = 8
  
  # Networking
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Storage
  enable_fsx_lustre = true
  fsx_storage_capacity = 14400 # 14.4TB
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = false
  
  # Monitoring
  enable_cloudwatch = true
  
  # Tags
  project_name = "multi-region-secondary"
  environment = "prod"
  
  tags = {
    Region      = "us-west-2"
    Purpose     = "Secondary Training Cluster"
    Owner       = "AI-Research"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
  }
}

# S3 Bucket for cross-region data sharing
resource "aws_s3_bucket" "shared_data" {
  provider = aws.us_east_1
  bucket   = "multi-region-hpc-shared-data-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Multi-Region HPC Shared Data"
    Environment = "production"
    Purpose     = "Cross-region data sharing"
  }
}

# Random string for bucket name
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# S3 Bucket versioning
resource "aws_s3_bucket_versioning" "shared_data" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.shared_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "shared_data" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.shared_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "shared_data" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.shared_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket replication to secondary region
resource "aws_s3_bucket_replication_configuration" "shared_data" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.shared_data.id

  role = aws_iam_role.replication.arn

  rule {
    id     = "replicate-to-west"
    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.shared_data_west.arn
    }
  }
}

# Secondary region S3 bucket
resource "aws_s3_bucket" "shared_data_west" {
  provider = aws.us_west_2
  bucket   = "multi-region-hpc-shared-data-west-${random_string.bucket_suffix.result}"
  
  tags = {
    Name        = "Multi-Region HPC Shared Data West"
    Environment = "production"
    Purpose     = "Cross-region data sharing"
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "replication" {
  provider = aws.us_east_1
  name     = "s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for S3 replication
resource "aws_iam_policy" "replication" {
  provider = aws.us_east_1
  name     = "s3-replication-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.shared_data.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.shared_data.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.shared_data_west.arn}/*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication" {
  provider   = aws.us_east_1
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# CloudWatch Dashboard for multi-region monitoring
resource "aws_cloudwatch_dashboard" "multi_region" {
  provider        = aws.us_east_1
  dashboard_name  = "multi-region-hpc-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.hpc_primary.autoscaling_group.name, { region = "us-east-1" }],
            ["...", module.hpc_secondary.autoscaling_group.name, { region = "us-west-2" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Multi-Region HPC CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/FSx", "DataReadBytes", "FileSystemId", module.hpc_primary.fsx_lustre.file_system_id, { region = "us-east-1" }],
            ["...", module.hpc_secondary.fsx_lustre.file_system_id, { region = "us-west-2" }]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Multi-Region FSx Performance"
        }
      }
    ]
  })
}

# Outputs
output "primary_cluster" {
  description = "Primary region cluster information"
  value = {
    region = "us-east-1"
    instances = module.hpc_primary.hpc_instances
    fsx = module.hpc_primary.fsx_lustre
    performance = module.hpc_primary.performance_benchmarks
  }
}

output "secondary_cluster" {
  description = "Secondary region cluster information"
  value = {
    region = "us-west-2"
    instances = module.hpc_secondary.hpc_instances
    fsx = module.hpc_secondary.fsx_lustre
    performance = module.hpc_secondary.performance_benchmarks
  }
}

output "shared_data_bucket" {
  description = "Cross-region shared data bucket"
  value = {
    primary_bucket = aws_s3_bucket.shared_data.bucket
    secondary_bucket = aws_s3_bucket.shared_data_west.bucket
    replication_role = aws_iam_role.replication.arn
  }
}

output "multi_region_setup" {
  description = "Multi-region setup summary"
  value = {
    primary_region = "us-east-1"
    secondary_region = "us-west-2"
    primary_instance_type = "p5.48xlarge"
    secondary_instance_type = "p4d.24xlarge"
    total_instances = module.hpc_primary.instance_count + module.hpc_secondary.instance_count
    dashboard_url = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=multi-region-hpc-dashboard"
  }
} 