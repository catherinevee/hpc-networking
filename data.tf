# High-Performance Networking Module Data Sources
# Data sources for AWS resources and configuration

# Get available availability zones
data "aws_availability_zones" "available" {
  state = "available"
  
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# Get current AWS region
data "aws_region" "current" {}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# Get VPC information
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Get latest Amazon Linux 2 AMI for EFA support
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get latest Ubuntu AMI for GPU workloads
data "aws_ami" "ubuntu_gpu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Get EFA-enabled instance types
data "aws_ec2_instance_type_offerings" "efa_enabled" {
  filter {
    name   = "instance-type"
    values = [
      "p5.48xlarge", "p5.24xlarge", "p5.12xlarge",
      "p4d.24xlarge", "p4de.24xlarge",
      "g5.48xlarge", "g5.24xlarge", "g5.12xlarge",
      "c6i.32xlarge", "c6i.24xlarge", "c6i.16xlarge"
    ]
  }

  filter {
    name   = "location"
    values = [data.aws_region.current.name]
  }
}

# Get default security group for VPC
data "aws_security_group" "default" {
  name   = "default"
  vpc_id = var.vpc_id
}

# Get route tables for VPC
data "aws_route_tables" "vpc" {
  vpc_id = var.vpc_id
}

# Get internet gateway for VPC
data "aws_internet_gateway" "vpc" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Get NAT gateways for VPC
data "aws_nat_gateways" "vpc" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Get EBS encryption by default setting
data "aws_ebs_encryption_by_default" "current" {}

# Get KMS key for encryption (if specified)
data "aws_kms_key" "ebs" {
  count = var.enable_encryption ? 1 : 0
  key_id = "alias/aws/ebs"
}

# Get CloudWatch log group for monitoring
data "aws_cloudwatch_log_group" "hpc_networking" {
  count = var.enable_cloudwatch ? 1 : 0
  name  = "/aws/hpc-networking/${var.project_name}"
}

# Get IAM role for EC2 instances (if specified)
data "aws_iam_role" "ec2_instance_profile" {
  count = var.iam_instance_profile != "" ? 1 : 0
  name  = var.iam_instance_profile
}

# Get subnet information for placement
data "aws_subnets" "private_compute" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*compute*"]
  }
}

data "aws_subnets" "private_storage" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "tag:Name"
    values = ["*storage*"]
  }
}

# Get FSx for Lustre file systems (if any exist)
data "aws_fsx_lustre_file_system" "existing" {
  count = var.enable_fsx_lustre ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  
  filter {
    name   = "file-system-type"
    values = ["LUSTRE"]
  }
}

# Get placement groups (if any exist)
data "aws_placement_group" "existing" {
  count = var.enable_efa ? 1 : 0
  
  filter {
    name   = "group-name"
    values = ["${var.project_name}-${var.environment}-efa"]
  }
}

# Get auto scaling groups (if any exist)
data "aws_autoscaling_groups" "existing" {
  count = var.enable_auto_scaling ? 1 : 0
  
  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

# Get launch templates (if any exist)
data "aws_launch_template" "existing" {
  count = var.enable_auto_scaling ? 1 : 0
  
  filter {
    name   = "tag:Project"
    values = [var.project_name]
  }
  
  filter {
    name   = "tag:Environment"
    values = [var.environment]
  }
}

# Get VPC endpoints (if any exist)
data "aws_vpc_endpoints" "existing" {
  count = var.enable_vpc_endpoints ? 1 : 0
  
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Get CloudWatch metrics for monitoring
data "aws_cloudwatch_metric_data" "network_metrics" {
  count = var.enable_cloudwatch ? 1 : 0
  
  metric_data_query {
    id = "network_bandwidth"
    metric_stat {
      metric {
        namespace = "AWS/EC2"
        metric_name = "NetworkBandwidthInGbps"
        dimensions {
          name = "InstanceType"
          value = var.instance_type
        }
      }
      period = 300
      stat = "Average"
    }
  }
  
  metric_data_query {
    id = "packet_drops"
    metric_stat {
      metric {
        namespace = "AWS/EC2"
        metric_name = "PacketDropCount"
        dimensions {
          name = "InstanceType"
          value = var.instance_type
        }
      }
      period = 300
      stat = "Sum"
    }
  }
  
  start_time = timeadd(timestamp(), "-1h")
  end_time   = timestamp()
} 