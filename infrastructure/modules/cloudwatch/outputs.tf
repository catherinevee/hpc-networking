# Outputs for CloudWatch Module

output "log_group_arns" {
  description = "The ARNs of the CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.main : k => v.arn }
}

output "log_group_names" {
  description = "The names of the CloudWatch log groups"
  value       = { for k, v in aws_cloudwatch_log_group.main : k => v.name }
}

output "alarm_arns" {
  description = "The ARNs of the CloudWatch alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.main : k => v.arn }
}

output "alarm_names" {
  description = "The names of the CloudWatch alarms"
  value       = { for k, v in aws_cloudwatch_metric_alarm.main : k => v.alarm_name }
}
