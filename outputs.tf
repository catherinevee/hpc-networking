# High-Performance Networking Module Outputs
# Comprehensive outputs for network interfaces, performance metrics, and resource information

# Network Interface Information
output "efa_network_interfaces" {
  description = "EFA network interface information"
  value = {
    for k, v in aws_network_interface.efa : k => {
      id = v.id
      private_ip = v.private_ip
      mac_address = v.mac_address
      interface_type = v.interface_type
      subnet_id = v.subnet_id
      availability_zone = v.availability_zone
      description = v.description
    }
  }
}

# Instance Information
output "hpc_instances" {
  description = "HPC instance information"
  value = {
    for k, v in aws_instance.hpc : k => {
      id = v.id
      private_ip = v.private_ip
      public_ip = v.public_ip
      instance_type = v.instance_type
      availability_zone = v.availability_zone
      placement_group = v.placement_group
      network_interface_id = v.network_interface[0].network_interface_id
    }
  }
}

# Auto Scaling Group Information
output "autoscaling_group" {
  description = "Auto scaling group information"
  value = var.enable_auto_scaling ? {
    id = aws_autoscaling_group.hpc[0].id
    name = aws_autoscaling_group.hpc[0].name
    desired_capacity = aws_autoscaling_group.hpc[0].desired_capacity
    min_size = aws_autoscaling_group.hpc[0].min_size
    max_size = aws_autoscaling_group.hpc[0].max_size
    vpc_zone_identifier = aws_autoscaling_group.hpc[0].vpc_zone_identifier
    placement_group = aws_autoscaling_group.hpc[0].placement_group
  } : null
}

# Placement Group Information
output "placement_group" {
  description = "Placement group information for EFA optimization"
  value = var.enable_efa ? {
    id = aws_placement_group.efa[0].id
    name = aws_placement_group.efa[0].name
    strategy = aws_placement_group.efa[0].strategy
  } : null
}

# Network Performance Metrics - UPDATED TO USE CONSOLIDATED METRICS
output "network_performance_metrics" {
  description = "Expected network performance metrics"
  value = local.performance_metrics
}

# Subnet Information
output "subnets" {
  description = "Subnet information for different tiers"
  value = {
    public_subnets = {
      ids = aws_subnet.public[*].id
      cidr_blocks = aws_subnet.public[*].cidr_block
      availability_zones = aws_subnet.public[*].availability_zone
    }
    private_compute_subnets = {
      ids = aws_subnet.private_compute[*].id
      cidr_blocks = aws_subnet.private_compute[*].cidr_block
      availability_zones = aws_subnet.private_compute[*].availability_zone
    }
    private_storage_subnets = {
      ids = aws_subnet.private_storage[*].id
      cidr_blocks = aws_subnet.private_storage[*].cidr_block
      availability_zones = aws_subnet.private_storage[*].availability_zone
    }
    private_endpoint_subnets = {
      ids = aws_subnet.private_endpoint[*].id
      cidr_blocks = aws_subnet.private_endpoint[*].cidr_block
      availability_zones = aws_subnet.private_endpoint[*].availability_zone
    }
  }
}

# Route Tables
output "route_tables" {
  description = "Route table information"
  value = {
    public_route_table_id = aws_route_table.public.id
    private_compute_route_table_ids = aws_route_table.private_compute[*].id
    private_storage_route_table_ids = aws_route_table.private_storage[*].id
    private_endpoint_route_table_ids = aws_route_table.private_endpoint[*].id
  }
}

# Security Groups
output "security_groups" {
  description = "Security group information"
  value = {
    efa_security_group_id = aws_security_group.efa.id
    efa_security_group_name = aws_security_group.efa.name
    fsx_security_group_id = var.enable_fsx_lustre ? aws_security_group.fsx[0].id : null
    fsx_security_group_name = var.enable_fsx_lustre ? aws_security_group.fsx[0].name : null
    vpc_endpoints_security_group_id = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints[0].id : null
    alb_security_group_id = var.enable_auto_scaling ? aws_security_group.alb[0].id : null
  }
}

# VPC Endpoints
output "vpc_endpoints" {
  description = "VPC endpoint information for cost optimization"
  value = var.enable_vpc_endpoints ? {
    s3_endpoint_id = aws_vpc_endpoint.s3[0].id
    dynamodb_endpoint_id = aws_vpc_endpoint.dynamodb[0].id
    sagemaker_api_endpoint_id = aws_vpc_endpoint.sagemaker_api[0].id
    sagemaker_runtime_endpoint_id = aws_vpc_endpoint.sagemaker_runtime[0].id
    fsx_endpoint_id = aws_vpc_endpoint.fsx[0].id
    efs_endpoint_id = aws_vpc_endpoint.efs[0].id
    ec2_endpoint_id = aws_vpc_endpoint.ec2[0].id
    ecr_api_endpoint_id = aws_vpc_endpoint.ecr_api[0].id
    ecr_dkr_endpoint_id = aws_vpc_endpoint.ecr_dkr[0].id
    logs_endpoint_id = aws_vpc_endpoint.logs[0].id
    monitoring_endpoint_id = aws_vpc_endpoint.monitoring[0].id
  } : null
}

# FSx for Lustre Information
output "fsx_lustre" {
  description = "FSx for Lustre file system information"
  value = var.enable_fsx_lustre ? {
    file_system_id = aws_fsx_lustre_file_system.hpc[0].id
    dns_name = aws_fsx_lustre_file_system.hpc[0].dns_name
    mount_name = aws_fsx_lustre_file_system.hpc[0].mount_name
    storage_capacity = aws_fsx_lustre_file_system.hpc[0].storage_capacity
    deployment_type = aws_fsx_lustre_file_system.hpc[0].deployment_type
    per_unit_storage_throughput = aws_fsx_lustre_file_system.hpc[0].per_unit_storage_throughput
    subnet_ids = aws_fsx_lustre_file_system.hpc[0].subnet_ids
    security_group_ids = aws_fsx_lustre_file_system.hpc[0].security_group_ids
    data_repository_association_id = aws_fsx_data_repository_association.hpc[0].id
    s3_bucket_name = aws_s3_bucket.data_repository[0].bucket
  } : null
}

# S3 Data Repository
output "s3_data_repository" {
  description = "S3 data repository information"
  value = var.enable_fsx_lustre ? {
    bucket_name = aws_s3_bucket.data_repository[0].bucket
    bucket_arn = aws_s3_bucket.data_repository[0].arn
    bucket_region = aws_s3_bucket.data_repository[0].region
  } : null
}

# IAM Roles and Policies
output "iam_roles" {
  description = "IAM roles and policies information"
  value = {
    ec2_role_arn = aws_iam_role.ec2_role.arn
    ec2_role_name = aws_iam_role.ec2_role.name
    ec2_instance_profile_arn = aws_iam_instance_profile.ec2_profile.arn
    ec2_instance_profile_name = aws_iam_instance_profile.ec2_profile.name
    cloudwatch_role_arn = var.enable_cloudwatch ? aws_iam_role.cloudwatch_role[0].arn : null
    cloudwatch_role_name = var.enable_cloudwatch ? aws_iam_role.cloudwatch_role[0].name : null
  }
}

# KMS Encryption
output "kms_encryption" {
  description = "KMS encryption key information"
  value = var.enable_encryption ? {
    key_id = aws_kms_key.hpc_encryption[0].id
    key_arn = aws_kms_key.hpc_encryption[0].arn
    alias_name = aws_kms_alias.hpc_encryption[0].name
    alias_arn = aws_kms_alias.hpc_encryption[0].arn
  } : null
}

# CloudWatch Monitoring
output "cloudwatch_monitoring" {
  description = "CloudWatch monitoring information"
  value = var.enable_cloudwatch ? {
    log_group_name = aws_cloudwatch_log_group.hpc_networking[0].name
    log_group_arn = aws_cloudwatch_log_group.hpc_networking[0].arn
    retention_days = aws_cloudwatch_log_group.hpc_networking[0].retention_in_days
    alarm_names = [for alarm in aws_cloudwatch_metric_alarm.network_alarms : alarm.alarm_name]
  } : null
}

# Launch Template (for Auto Scaling)
output "launch_template" {
  description = "Launch template information for auto scaling"
  value = var.enable_auto_scaling ? {
    id = aws_launch_template.hpc[0].id
    name = aws_launch_template.hpc[0].name
    latest_version = aws_launch_template.hpc[0].latest_version
    default_version = aws_launch_template.hpc[0].default_version
  } : null
}

# Network ACLs
output "network_acls" {
  description = "Network ACL information"
  value = {
    compute_nacl_id = aws_network_acl.compute.id
    storage_nacl_id = var.enable_fsx_lustre ? aws_network_acl.storage[0].id : null
  }
}

# NAT Gateways
output "nat_gateways" {
  description = "NAT gateway information"
  value = {
    nat_gateway_ids = aws_nat_gateway.main[*].id
    nat_gateway_public_ips = aws_eip.nat[*].public_ip
    nat_gateway_private_ips = aws_nat_gateway.main[*].private_ip
  }
}

# Environment Variables for EFA Optimization
output "efa_environment_variables" {
  description = "Environment variables for EFA optimization"
  value = local.efa_environment_vars
  sensitive = false
}

# Network Tuning Parameters
output "network_tuning_parameters" {
  description = "Network tuning parameters for performance optimization"
  value = local.network_tuning_params
  sensitive = false
}

# Cost Optimization Information
output "cost_optimization" {
  description = "Cost optimization configuration"
  value = {
    vpc_endpoints_enabled = var.enable_vpc_endpoints
    spot_instances_allowed = var.allow_spot_instances
    single_az_deployment = local.single_az_deployment
    encryption_enabled = var.enable_encryption
    auto_scaling_enabled = var.enable_auto_scaling
  }
}

# Connection Information
output "connection_info" {
  description = "Connection information for instances"
  value = {
    ssh_command = var.key_name != "" ? "ssh -i ${var.key_name}.pem ubuntu@<instance_private_ip>" : "SSH key not configured"
    instance_count = var.instance_count
    instance_type = var.instance_type
    placement_strategy = var.placement_strategy
    efa_enabled = var.enable_efa
    gpu_count = local.gpu_count_by_instance[var.instance_type]
  }
}

# Performance Benchmarks - UPDATED TO USE CONSOLIDATED METRICS
output "performance_benchmarks" {
  description = "Expected performance benchmarks"
  value = {
    expected_bandwidth_gbps = local.performance_metrics.expected_bandwidth_gbps
    expected_latency_us = local.performance_metrics.expected_latency_us
    fsx_throughput_mibps = var.enable_fsx_lustre ? (var.fsx_storage_capacity / 1024) * 1000 : null
    efa_generation = local.performance_metrics.efa_version
    gpu_interconnect_bandwidth = local.performance_metrics.gpu_count > 0 ? "NVSwitch" : "N/A"
  }
}

# Resource Tags
output "resource_tags" {
  description = "Common tags applied to all resources"
  value = local.common_tags
  sensitive = false
}

# Module Configuration Summary
output "module_summary" {
  description = "Summary of module configuration"
  value = {
    project_name = var.project_name
    environment = var.environment
    region = var.region
    vpc_id = var.vpc_id
    instance_type = var.instance_type
    instance_count = var.instance_count
    enable_efa = var.enable_efa
    enable_gdr = var.enable_gdr
    enable_fsx_lustre = var.enable_fsx_lustre
    enable_auto_scaling = var.enable_auto_scaling
    enable_vpc_endpoints = var.enable_vpc_endpoints
    enable_cloudwatch = var.enable_cloudwatch
    enable_encryption = var.enable_encryption
    placement_strategy = var.placement_strategy
    subnet_count = {
      public = length(local.public_subnets)
      compute = length(local.private_compute_subnets)
      storage = length(local.private_storage_subnets)
      endpoint = length(local.private_endpoint_subnets)
    }
  }
} 