# KMS Key outputs
output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.hpc.arn
}

output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.hpc.key_id
}

# SNS Topic outputs
output "sns_topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.hpc_alerts.arn
}

# CloudWatch outputs
output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.efa_monitoring.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.efa_monitoring.arn
}
