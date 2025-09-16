# Outputs for ParallelCluster Module

output "cluster_id" {
  description = "The ID of the cluster"
  value       = var.create_cluster ? aws_instance.placeholder[0].id : null
}

output "cluster_arn" {
  description = "The ARN of the cluster"
  value       = var.create_cluster ? aws_instance.placeholder[0].arn : null
}

output "head_node_ip" {
  description = "The IP address of the head node"
  value       = var.create_cluster ? aws_instance.placeholder[0].private_ip : null
}
