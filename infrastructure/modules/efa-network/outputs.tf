# Outputs for EFA Network Module

output "security_group_id" {
  description = "ID of the EFA security group"
  value       = aws_security_group.efa.id
}

output "security_group_arn" {
  description = "ARN of the EFA security group"
  value       = aws_security_group.efa.arn
}

output "placement_group_id" {
  description = "ID of the EFA cluster placement group"
  value       = aws_placement_group.efa_cluster.id
}

output "placement_group_name" {
  description = "Name of the EFA cluster placement group"
  value       = aws_placement_group.efa_cluster.name
}

output "partition_placement_group_ids" {
  description = "IDs of the EFA partition placement groups"
  value       = aws_placement_group.efa_partition[*].id
}

output "partition_placement_group_names" {
  description = "Names of the EFA partition placement groups"
  value       = aws_placement_group.efa_partition[*].name
}

output "launch_template_id" {
  description = "ID of the EFA launch template"
  value       = aws_launch_template.efa.id
}

output "launch_template_arn" {
  description = "ARN of the EFA launch template"
  value       = aws_launch_template.efa.arn
}

output "launch_template_latest_version" {
  description = "Latest version of the EFA launch template"
  value       = aws_launch_template.efa.latest_version
}

output "iam_role_arn" {
  description = "ARN of the EFA IAM role"
  value       = aws_iam_role.efa.arn
}

output "iam_instance_profile_arn" {
  description = "ARN of the EFA IAM instance profile"
  value       = aws_iam_instance_profile.efa.arn
}

output "network_interface_id" {
  description = "ID of the EFA network interface"
  value       = var.create_efa_interface ? aws_network_interface.efa[0].id : null
}

output "network_interface_private_ip" {
  description = "Private IP of the EFA network interface"
  value       = var.create_efa_interface ? aws_network_interface.efa[0].private_ip : null
}

output "cloudwatch_log_group_name" {
  description = "Name of the EFA CloudWatch log group"
  value       = aws_cloudwatch_log_group.efa.name
}

output "cloudwatch_log_group_arn" {
  description = "ARN of the EFA CloudWatch log group"
  value       = aws_cloudwatch_log_group.efa.arn
}

output "cloudwatch_metric_filter_name" {
  description = "Name of the EFA latency metric filter"
  value       = aws_cloudwatch_log_metric_filter.efa_latency.name
}

output "cloudwatch_alarm_name" {
  description = "Name of the EFA high latency alarm"
  value       = aws_cloudwatch_metric_alarm.efa_high_latency.alarm_name
}

output "cloudwatch_alarm_arn" {
  description = "ARN of the EFA high latency alarm"
  value       = aws_cloudwatch_metric_alarm.efa_high_latency.arn
}
