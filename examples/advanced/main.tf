# Advanced HPC Networking Example
# Auto-scaling cluster with spot instances and comprehensive monitoring

terraform {
  required_version = "1.12.2"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  id = "vpc-12345678" # Replace with your VPC ID
}

# Advanced HPC Networking Module
module "hpc_networking" {
  source = "../../"

  # Required variables
  vpc_id = data.aws_vpc.existing.id
  
  # Auto scaling configuration
  enable_auto_scaling = true
  min_size = 2
  max_size = 16
  desired_capacity = 8
  
  # Performance optimization
  instance_type = "p5.48xlarge"
  enable_efa = true
  enable_gdr = true
  placement_strategy = "cluster"
  
  # Advanced networking
  enable_jumbo_frames = true
  enable_sriov = true
  numa_optimization = true
  
  # Storage with data repository
  enable_fsx_lustre = true
  fsx_storage_capacity = 28800 # 28.8TB
  fsx_deployment_type = "PERSISTENT_2"
  
  # Security
  enable_encryption = true
  allowed_cidr_blocks = ["10.0.0.0/16", "192.168.1.0/24"]
  key_name = "hpc-key-pair" # Replace with your key pair name
  
  # Cost optimization
  enable_vpc_endpoints = true
  allow_spot_instances = true
  spot_max_price = "80" # 80% of on-demand
  
  # Monitoring and alerting
  enable_cloudwatch = true
  cloudwatch_retention_days = 90
  
  # Tags
  project_name = "advanced-training"
  environment = "prod"
  
  tags = {
    Project     = "BERT-Training"
    Environment = "production"
    Owner       = "AI-Research"
    CostCenter  = "AI-Infrastructure"
    DataClass   = "Confidential"
    Purpose     = "Advanced Training Cluster"
    AutoScaling = "enabled"
    SpotInstances = "enabled"
  }
}

# Additional CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "hpc_dashboard" {
  dashboard_name = "hpc-networking-dashboard"

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
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", module.hpc_networking.autoscaling_group.name],
            [".", "NetworkIn", ".", "."],
            [".", "NetworkOut", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "HPC Cluster Metrics"
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
            ["AWS/FSx", "DataReadBytes", "FileSystemId", module.hpc_networking.fsx_lustre.file_system_id],
            [".", "DataWriteBytes", ".", "."],
            [".", "MetadataOperations", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "FSx for Lustre Performance"
        }
      }
    ]
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "hpc_alerts" {
  name = "hpc-networking-alerts"
  
  tags = {
    Name = "HPC Networking Alerts"
    Environment = "production"
  }
}

# CloudWatch Alarm for high CPU utilization
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "hpc-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "This metric monitors EC2 CPU utilization"
  alarm_actions       = [aws_sns_topic.hpc_alerts.arn]

  dimensions = {
    AutoScalingGroupName = module.hpc_networking.autoscaling_group.name
  }
}

# CloudWatch Alarm for low CPU utilization (scale down)
resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "hpc-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "30"
  alarm_description   = "This metric monitors EC2 CPU utilization for scale down"
  alarm_actions       = [aws_sns_topic.hpc_alerts.arn]

  dimensions = {
    AutoScalingGroupName = module.hpc_networking.autoscaling_group.name
  }
}

# Outputs
output "autoscaling_group" {
  description = "Auto scaling group information"
  value = module.hpc_networking.autoscaling_group
}

output "fsx_information" {
  description = "FSx for Lustre information"
  value = module.hpc_networking.fsx_lustre
}

output "performance_benchmarks" {
  description = "Expected performance benchmarks"
  value = module.hpc_networking.performance_benchmarks
}

output "cost_optimization" {
  description = "Cost optimization configuration"
  value = module.hpc_networking.cost_optimization
}

output "monitoring_setup" {
  description = "Monitoring and alerting setup"
  value = {
    dashboard_url = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=hpc-networking-dashboard"
    sns_topic_arn = aws_sns_topic.hpc_alerts.arn
    log_group_name = module.hpc_networking.cloudwatch_monitoring.log_group_name
  }
} 