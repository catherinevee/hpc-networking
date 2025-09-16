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
  skip_outputs = true
}

inputs = {
  # CloudWatch Log Groups
  log_groups = {
    for name, config in local.cloudwatch_config.log_groups : name => {
      name              = config.name
      retention_in_days = config.retention_in_days
      kms_key_id        = dependency.kms.outputs.kms_key_arn
    }
  }
  
  # CloudWatch Alarms
  alarms = {
    high_queue_depth = {
      alarm_name          = local.cloudwatch_config.alarms.high_queue_depth.alarm_name
      comparison_operator = local.cloudwatch_config.alarms.high_queue_depth.comparison_operator
      evaluation_periods  = local.cloudwatch_config.alarms.high_queue_depth.evaluation_periods
      metric_name         = local.cloudwatch_config.alarms.high_queue_depth.metric_name
      namespace           = local.cloudwatch_config.alarms.high_queue_depth.namespace
      period              = local.cloudwatch_config.alarms.high_queue_depth.period
      statistic           = local.cloudwatch_config.alarms.high_queue_depth.statistic
      threshold           = local.cloudwatch_config.alarms.high_queue_depth.threshold
      alarm_description   = local.cloudwatch_config.alarms.high_queue_depth.alarm_description
      alarm_actions       = [dependency.kms.outputs.sns_topic_arn]
      ok_actions          = [dependency.kms.outputs.sns_topic_arn]
      treat_missing_data  = local.cloudwatch_config.alarms.high_queue_depth.treat_missing_data
    }
  }
  
  # Tags
  tags = merge(local.common_tags, {
    Name = "hpc-${local.environment}-cloudwatch"
    Type = "CloudWatch"
    Purpose = "Monitoring"
  })
}