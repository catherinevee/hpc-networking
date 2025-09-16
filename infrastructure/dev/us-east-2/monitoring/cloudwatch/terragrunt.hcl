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
dependency "kms" {
  config_path = "../../networking/efa-sg"
}

inputs = {
  # CloudWatch Log Groups
  log_groups = {
    hpc_system_logs = {
      name              = "/aws/hpc/${local.environment}/system"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id        = dependency.kms.outputs.kms_key_arn
    }
    hpc_application_logs = {
      name              = "/aws/hpc/${local.environment}/application"
      retention_in_days = local.monitoring.cloudwatch.log_retention_days
      kms_key_id        = dependency.kms.outputs.kms_key_arn
    }
  }
  
  # CloudWatch Alarms
  alarms = {
    high_queue_depth = {
      alarm_name          = "hpc-${local.environment}-high-queue-depth"
      comparison_operator = "GreaterThanThreshold"
      evaluation_periods  = "2"
      metric_name         = "JobsQueued"
      namespace           = "AWS/ParallelCluster"
      period              = "300"
      statistic           = "Average"
      threshold           = "100"
      alarm_description   = "This metric monitors high queue depth"
      alarm_actions       = [dependency.kms.outputs.sns_topic_arn]
      ok_actions          = [dependency.kms.outputs.sns_topic_arn]
      treat_missing_data  = "notBreaching"
    }
  }
  
  # Tags
  tags = {
    Name = "hpc-${local.environment}-cloudwatch"
    Type = "CloudWatch"
    Purpose = "Monitoring"
    Environment = local.environment
    Region = local.region
  }
}