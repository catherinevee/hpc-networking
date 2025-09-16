# EFA Network Module for HPC Infrastructure
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# EFA Security Group
resource "aws_security_group" "efa" {
  name_prefix = "${var.cluster_name}-efa-"
  vpc_id      = var.vpc_id
  description = "Security group for EFA-enabled instances"

  # EFA communication port
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "EFA communication"
  }

  # MPI communication ports
  ingress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "MPI communication"
  }

  # All traffic within security group
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
    description = "All traffic within security group"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-sg"
    Type = "EFA-SecurityGroup"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Cluster Placement Group for EFA instances
resource "aws_placement_group" "efa_cluster" {
  name     = "${var.cluster_name}-efa-cluster"
  strategy = "cluster"
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-cluster"
    Type = "EFA-PlacementGroup"
  })
}

# Partition Placement Groups for large clusters
resource "aws_placement_group" "efa_partition" {
  count = var.enable_partition_strategy ? var.partition_count : 0
  
  name     = "${var.cluster_name}-efa-partition-${count.index + 1}"
  strategy = "partition"
  partition_count = 1
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-partition-${count.index + 1}"
    Type = "EFA-PartitionGroup"
    Partition = count.index + 1
  })
}

# Launch Template for EFA-enabled instances
resource "aws_launch_template" "efa" {
  name_prefix   = "${var.cluster_name}-efa-"
  description   = "Launch template for EFA-enabled HPC instances"
  image_id      = var.ami_id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.efa.id]
  
  # EFA configuration
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 2
  }
  
  # User data for EFA setup
  user_data = base64encode(templatefile("${path.module}/efa_user_data.sh", {
    cluster_name = var.cluster_name
    efa_device = var.efa_device
    mtu_size = var.mtu_size
    enable_gpudirect = var.enable_gpudirect
  }))
  
  # IAM instance profile
  iam_instance_profile {
    name = aws_iam_instance_profile.efa.name
  }
  
  # EBS optimization
  ebs_optimized = true
  
  # Block device mappings
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_type           = "gp3"
      volume_size           = var.root_volume_size
      iops                  = 3000
      throughput            = 125
      encrypted             = true
      delete_on_termination = true
    }
  }
  
  # Additional EBS volumes for local storage
  dynamic "block_device_mappings" {
    for_each = var.additional_ebs_volumes
    content {
      device_name = block_device_mappings.value.device_name
      ebs {
        volume_type           = block_device_mappings.value.volume_type
        volume_size           = block_device_mappings.value.volume_size
        iops                  = block_device_mappings.value.iops
        throughput            = block_device_mappings.value.throughput
        encrypted             = true
        delete_on_termination = false
      }
    }
  }
  
  # Placement configuration
  placement {
    availability_zone = var.availability_zone
    group_name        = aws_placement_group.efa_cluster.name
  }
  
  # CPU options for optimal performance
  cpu_options {
    core_count       = var.cpu_core_count
    threads_per_core = var.threads_per_core
  }
  
  # Credit specification for burstable instances
  credit_specification {
    cpu_credits = var.cpu_credits
  }
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-template"
    Type = "EFA-LaunchTemplate"
  })
}

# IAM Role for EFA instances
resource "aws_iam_role" "efa" {
  name = "${var.cluster_name}-efa-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-role"
    Type = "EFA-IAMRole"
  })
}

# IAM Policy for EFA instances
resource "aws_iam_role_policy" "efa" {
  name = "${var.cluster_name}-efa-policy"
  role = aws_iam_role.efa.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcs",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeSnapshots",
          "ec2:DescribeImages",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcClassicLinkDnsSupport",
          "ec2:DescribeVpcEndpointServices",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcClassicLinkDnsSupport",
          "ec2:DescribeVpcEndpointServices",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcPeeringConnections"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "efa" {
  name = "${var.cluster_name}-efa-profile"
  role = aws_iam_role.efa.name
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-profile"
    Type = "EFA-InstanceProfile"
  })
}

# EFA Network Interface
resource "aws_network_interface" "efa" {
  count = var.create_efa_interface ? 1 : 0
  
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.efa.id]
  private_ips       = var.private_ips
  source_dest_check = false
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-interface"
    Type = "EFA-NetworkInterface"
  })
}

# CloudWatch Log Group for EFA logs
resource "aws_cloudwatch_log_group" "efa" {
  name              = "/aws/hpc/${var.cluster_name}/efa"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-logs"
    Type = "EFA-LogGroup"
  })
}

# CloudWatch Metric Filter for EFA performance
resource "aws_cloudwatch_log_metric_filter" "efa_latency" {
  name           = "${var.cluster_name}-efa-latency"
  log_group_name = aws_cloudwatch_log_group.efa.name
  pattern        = "[timestamp, level, message=\"EFA latency\", latency]"
  
  metric_transformation {
    name      = "EFALatency"
    namespace = "HPC/EFA"
    value     = "$latency"
    
    default_value = "0"
  }
}

# CloudWatch Alarm for high EFA latency
resource "aws_cloudwatch_metric_alarm" "efa_high_latency" {
  alarm_name          = "${var.cluster_name}-efa-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EFALatency"
  namespace           = "HPC/EFA"
  period              = 60
  statistic           = "Average"
  threshold           = 20  # microseconds
  alarm_description   = "High EFA latency detected"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  
  tags = merge(var.tags, {
    Name = "${var.cluster_name}-efa-high-latency-alarm"
    Type = "EFA-Alarm"
  })
}
