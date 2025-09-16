# CloudWatch Monitoring for Dev Environment
# Simplified configuration with hardcoded values to avoid locals loading issues

terraform {
  source = "../../../../modules/cloudwatch"
}

# Dependencies
dependency "kms" {
  config_path = "../../networking/efa-sg"
  skip_outputs = true
}

inputs = {
  # CloudWatch Log Groups - Hardcoded for dev environment
  log_groups = {
    parallel_cluster = {
      name              = "/aws/parallelcluster/hpc-dev"
      retention_in_days = 7
      kms_key_id        = "arn:aws:kms:us-east-2:025066254478:key/placeholder"  # Will be replaced when KMS is applied
    }
    vpc_flow_logs = {
      name              = "/aws/vpc/flow-logs/hpc-dev"
      retention_in_days = 7
      kms_key_id        = "arn:aws:kms:us-east-2:025066254478:key/placeholder"  # Will be replaced when KMS is applied
    }
  }
  
  # CloudWatch Alarms - Hardcoded for dev environment
  alarms = {
    high_queue_depth = {
      alarm_name          = "hpc-dev-HighQueueDepth"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = 2
      metric_name         = "QueueDepth"
      namespace           = "AWS/SQS"
      period              = 300
      statistic           = "Average"
      threshold           = 100
      alarm_description   = "Alarm when SQS queue depth is high"
      alarm_actions       = ["arn:aws:sns:us-east-2:025066254478:placeholder"]  # Will be replaced when SNS is applied
      ok_actions          = ["arn:aws:sns:us-east-2:025066254478:placeholder"]  # Will be replaced when SNS is applied
      treat_missing_data  = "notBreaching"
    }
  }
  
  # Tags - Hardcoded for dev environment
  tags = {
    Environment = "dev"
    Region = "us-east-2"
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
    Name = "hpc-dev-cloudwatch"
    Type = "CloudWatch"
    Purpose = "Monitoring"
  }
}