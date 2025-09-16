# Outputs for FSx Lustre Module

output "file_system_id" {
  description = "The ID of the FSx Lustre file system"
  value       = aws_fsx_lustre_file_system.main.id
}

output "file_system_arn" {
  description = "The ARN of the FSx Lustre file system"
  value       = aws_fsx_lustre_file_system.main.arn
}

output "dns_name" {
  description = "The DNS name of the file system"
  value       = aws_fsx_lustre_file_system.main.dns_name
}

output "mount_name" {
  description = "The mount name of the file system"
  value       = aws_fsx_lustre_file_system.main.mount_name
}

output "network_interface_ids" {
  description = "The network interface IDs of the file system"
  value       = aws_fsx_lustre_file_system.main.network_interface_ids
}

output "vpc_id" {
  description = "The VPC ID of the file system"
  value       = aws_fsx_lustre_file_system.main.vpc_id
}

output "subnet_ids" {
  description = "The subnet IDs of the file system"
  value       = aws_fsx_lustre_file_system.main.subnet_ids
}

output "security_group_ids" {
  description = "The security group IDs of the file system"
  value       = aws_fsx_lustre_file_system.main.security_group_ids
}
