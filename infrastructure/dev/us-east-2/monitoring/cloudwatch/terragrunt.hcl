# CloudWatch Monitoring for Dev Environment
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
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-cloudwatch.git?ref=v1.0.0"
}

# Dependencies
dependency "vpc" {
  config_path = "../../networking/vpc"
}

dependency "kms" {
  config_path = "../../networking/efa-sg"
}

inputs = {
  # CloudWatch Log Groups
  log_groups = {
    hpc_system_logs = {
      name = "/aws/hpc/${local.environment}/system"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id = dependency.kms.outputs.kms_key_arn
    }
    slurm_logs = {
      name = "/aws/hpc/${local.environment}/slurm"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id = dependency.kms.outputs.kms_key_arn
    }
    mpi_logs = {
      name = "/aws/hpc/${local.environment}/mpi"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id = dependency.kms.outputs.kms_key_arn
    }
    application_logs = {
      name = "/aws/hpc/${local.environment}/applications"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id = dependency.kms.outputs.kms_key_arn
    }
    vpc_flow_logs = {
      name = "/aws/vpc/flowlogs/${local.environment}"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id = dependency.kms.outputs.kms_key_arn
    }
  }
  
  # CloudWatch Dashboards
  dashboards = {
    hpc_overview = {
      dashboard_name = "HPC-${title(local.environment)}-Overview"
      dashboard_body = jsonencode({
        widgets = [
          {
            type = "metric"
            x = 0
            y = 0
            width = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/EC2", "CPUUtilization", "InstanceId", "i-0123456789abcdef0"],
                [".", "NetworkIn", ".", "."],
                [".", "NetworkOut", ".", "."]
              ]
              view = "timeSeries"
              stacked = false
              region = local.region
              title = "EC2 Metrics"
              period = 300
            }
          },
          {
            type = "metric"
            x = 12
            y = 0
            width = 12
            height = 6
            properties = {
              metrics = [
                ["AWS/FSx", "DataReadBytes", "FileSystemId", "fs-0123456789abcdef0"],
                [".", "DataWriteBytes", ".", "."],
                [".", "DataReadOperations", ".", "."],
                [".", "DataWriteOperations", ".", "."]
              ]
              view = "timeSeries"
              stacked = false
              region = local.region
              title = "FSx Lustre Metrics"
              period = 300
            }
          },
          {
            type = "log"
            x = 0
            y = 6
            width = 24
            height = 6
            properties = {
              query = "SOURCE '/aws/hpc/${local.environment}/system' | fields @timestamp, @message | sort @timestamp desc | limit 100"
              region = local.region
              title = "System Logs"
            }
          }
        ]
      })
    }
    
    network_performance = {
      dashboard_name = "HPC-${title(local.environment)}-Network"
      dashboard_body = jsonencode({
        widgets = [
          {
            type = "metric"
            x = 0
            y = 0
            width = 12
            height = 6
            properties = {
              metrics = [
                ["HPC/EFA", "EFALatency"],
                [".", "EFABandwidth"]
              ]
              view = "timeSeries"
              stacked = false
              region = local.region
              title = "EFA Performance"
              period = 60
            }
          },
          {
            type = "metric"
            x = 12
            y = 0
            width = 12
            height = 6
            properties = {
              metrics = [
                ["HPC/Network", "MPILatency"],
                [".", "NetworkCongestion"]
              ]
              view = "timeSeries"
              stacked = false
              region = local.region
              title = "MPI Performance"
              period = 60
            }
          }
        ]
      })
    }
  }
  
  # CloudWatch Alarms
  alarms = {
    high_queue_depth = {
      alarm_name = "hpc-high-queue-depth-${local.environment}"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods = 2
      metric_name = "QueueDepth"
      namespace = "HPC/Scheduler"
      period = 300
      statistic = "Average"
      threshold = 100
      alarm_description = "High queue depth detected"
      alarm_actions = [aws_sns_topic.hpc_alerts.arn]
      ok_actions = [aws_sns_topic.hpc_alerts.arn]
      treat_missing_data = "notBreaching"
    }
    
    low_storage_space = {
      alarm_name = "hpc-low-storage-space-${local.environment}"
      comparison_operator = "LessThanThreshold"
      evaluation_periods = 1
      metric_name = "FreeStorageSpace"
      namespace = "AWS/FSx"
      period = 300
      statistic = "Average"
      threshold = 1000000000000  # 1TB in bytes
      alarm_description = "Low storage space detected"
      alarm_actions = [aws_sns_topic.hpc_alerts.arn]
      ok_actions = [aws_sns_topic.hpc_alerts.arn]
      treat_missing_data = "notBreaching"
    }
    
    high_mpi_latency = {
      alarm_name = "hpc-high-mpi-latency-${local.environment}"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods = 3
      metric_name = "MPILatency"
      namespace = "HPC/Network"
      period = 60
      statistic = "Average"
      threshold = 20  # microseconds
      alarm_description = "High MPI latency detected"
      alarm_actions = [aws_sns_topic.hpc_alerts.arn]
      ok_actions = [aws_sns_topic.hpc_alerts.arn]
      treat_missing_data = "notBreaching"
    }
  }
  
  # VPC Flow Logs
  vpc_flow_logs = {
    log_destination_type = "s3"
    log_destination = "arn:aws:s3:::${aws_s3_bucket.flow_logs.bucket}/vpc-flow-logs/"
    traffic_type = "ALL"
    log_format = "$version $account-id $interface-id $srcaddr $dstaddr $srcport $dstport $protocol $packets $bytes $windowstart $windowend $action $tcp-flags $flow-log-status"
  }
  
  # Tags
  tags = merge(local.common_tags, {
    Component = "CloudWatch"
    Tier = "Monitoring"
  })
}

# SNS Topic for alerts
resource "aws_sns_topic" "hpc_alerts" {
  name = "hpc-${local.environment}-alerts"
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-alerts"
    Type = "SNS-Topic"
  })
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "hpc_alerts" {
  arn = aws_sns_topic.hpc_alerts.arn
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "sns:Publish"
        Resource = aws_sns_topic.hpc_alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# S3 Bucket for VPC Flow Logs
resource "aws_s3_bucket" "flow_logs" {
  bucket = "hpc-vpc-flow-logs-${local.environment}-${random_id.bucket_suffix.hex}"
  
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-flow-logs"
    Type = "S3-Bucket"
  })
}

# Random ID for bucket suffix
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Data source for current account
data "aws_caller_identity" "current" {}
