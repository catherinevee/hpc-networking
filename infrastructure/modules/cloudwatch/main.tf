# CloudWatch Module for HPC Infrastructure
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "main" {
  for_each = var.log_groups

  name              = each.value.name
  retention_in_days = each.value.retention_in_days
  kms_key_id        = each.value.kms_key_id

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "main" {
  for_each = var.alarms

  alarm_name          = each.value.alarm_name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.alarm_description
  alarm_actions       = each.value.alarm_actions
  ok_actions          = each.value.ok_actions
  treat_missing_data  = each.value.treat_missing_data

  tags = merge(var.tags, {
    Name = each.value.alarm_name
  })
}
