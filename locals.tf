# High-Performance Networking Module Locals
# Computed values and performance specifications

locals {
  # Common tags for all resources
  common_tags = merge({
    Environment         = var.environment
    Project            = var.project_name
    ManagedBy          = "Terraform"
    NetworkTier        = "HighPerformance"
    CostCenter         = "AI-ML-Infrastructure"
    DataClassification = "Confidential"
    BackupPolicy       = "Daily"
    NetworkOptimized   = "true"
    EFAEnabled         = var.enable_efa
    GPUDirectEnabled   = var.enable_gdr
    InstanceType       = var.instance_type
    PlacementStrategy  = var.placement_strategy
  }, var.tags)

  # Performance specifications by instance type
  bandwidth_by_instance = {
    # P5 series - 3rd gen EFA, up to 3,200 Gbps
    "p5.48xlarge" = 3200
    "p5.24xlarge" = 1600
    "p5.12xlarge" = 800
    # P4 series - 2nd gen EFA, up to 400 Gbps
    "p4d.24xlarge"  = 400
    "p4de.24xlarge" = 400
    # G5 series - 1st gen EFA, up to 100 Gbps
    "g5.48xlarge" = 100
    "g5.24xlarge" = 100
    "g5.12xlarge" = 100
    # C6i series - CPU optimized with EFA
    "c6i.32xlarge" = 50
    "c6i.24xlarge" = 50
    "c6i.16xlarge" = 50
  }

  # EFA generation by instance type
  efa_generation = {
    # P5 series - 3rd gen EFA
    "p5.48xlarge" = "3rd"
    "p5.24xlarge" = "3rd"
    "p5.12xlarge" = "3rd"
    # P4 series - 2nd gen EFA
    "p4d.24xlarge"  = "2nd"
    "p4de.24xlarge" = "2nd"
    # G5 series - 1st gen EFA
    "g5.48xlarge" = "1st"
    "g5.24xlarge" = "1st"
    "g5.12xlarge" = "1st"
    # C6i series - 1st gen EFA
    "c6i.32xlarge" = "1st"
    "c6i.24xlarge" = "1st"
    "c6i.16xlarge" = "1st"
  }

  # GPU count by instance type
  gpu_count_by_instance = {
    # P5 series - H100 GPUs
    "p5.48xlarge" = 8
    "p5.24xlarge" = 4
    "p5.12xlarge" = 2
    # P4 series - A100 GPUs
    "p4d.24xlarge"  = 8
    "p4de.24xlarge" = 8
    # G5 series - Various GPUs
    "g5.48xlarge" = 8
    "g5.24xlarge" = 4
    "g5.12xlarge" = 2
    # C6i series - No GPUs
    "c6i.32xlarge" = 0
    "c6i.24xlarge" = 0
    "c6i.16xlarge" = 0
  }

  # Expected latency by placement strategy
  latency_by_placement = {
    "cluster"   = 50   # microseconds
    "partition" = 200  # microseconds
    "spread"    = 500  # microseconds
  }

  # Cost optimization settings
  single_az_deployment = var.environment != "prod"
  
  # VPC endpoints for cost optimization
  vpc_endpoints = var.enable_vpc_endpoints ? [
    "s3",
    "dynamodb", 
    "sagemaker.api",
    "sagemaker.runtime",
    "fsx",
    "efs",
    "ec2",
    "ecr.api",
    "ecr.dkr",
    "logs",
    "monitoring"
  ] : []
  
  # Spot instances for non-production
  use_spot = var.environment != "prod" && var.allow_spot_instances

  # Network optimization settings
  mtu_size = var.enable_jumbo_frames ? 9001 : 1500
  
  # Subnet availability zones
  availability_zones = data.aws_availability_zones.available.names
  
  # Subnet configuration
  public_subnets = [
    for i, cidr in var.subnet_configuration.public_subnets : {
      cidr_block = cidr
      az         = local.availability_zones[i % length(local.availability_zones)]
    }
  ]
  
  private_compute_subnets = [
    for i, cidr in var.subnet_configuration.private_compute_subnets : {
      cidr_block = cidr
      az         = local.availability_zones[i % length(local.availability_zones)]
    }
  ]
  
  private_storage_subnets = [
    for i, cidr in var.subnet_configuration.private_storage_subnets : {
      cidr_block = cidr
      az         = local.availability_zones[i % length(local.availability_zones)]
    }
  ]
  
  private_endpoint_subnets = [
    for i, cidr in var.subnet_configuration.private_endpoint_subnets : {
      cidr_block = cidr
      az         = local.availability_zones[i % length(local.availability_zones)]
    }
  ]

  # EFA environment variables for optimization
  efa_environment_vars = {
    "FI_EFA_FORK_SAFE"        = "1"
    "FI_EFA_USE_DEVICE_RDMA"  = "1"
    "NCCL_NET_GDR_LEVEL"      = "2"
    "NCCL_ALGO"               = "Ring"
    "NCCL_DEBUG"              = "INFO"
    "NCCL_IB_DISABLE"         = "1"
    "NCCL_P2P_DISABLE"        = "1"
    "NCCL_SHM_DISABLE"        = "1"
    "NCCL_NET_GDR_LEVEL"      = "2"
    "NCCL_IB_HCA"             = "mlx5_0"
    "NCCL_IB_TIMEOUT"         = "23"
    "NCCL_IB_RETRY_CNT"       = "7"
    "NCCL_IB_SL"              = "0"
    "NCCL_IB_TC"              = "41"
    "NCCL_IB_AR_THRESHOLD"    = "8192"
    "NCCL_IB_CUDA_SUPPORT"    = "1"
  }

  # Network performance tuning parameters
  network_tuning_params = {
    # TCP optimization
    "net.core.rmem_max"           = "268435456"
    "net.core.wmem_max"           = "268435456"
    "net.ipv4.tcp_rmem"           = "4096 87380 268435456"
    "net.ipv4.tcp_wmem"           = "4096 65536 268435456"
    "net.ipv4.tcp_congestion_control" = "bbr"
    "net.ipv4.tcp_window_scaling" = "1"
    "net.ipv4.tcp_timestamps"     = "1"
    "net.ipv4.tcp_sack"           = "1"
    
    # EFA optimization
    "options mlx5_core num_vfs"   = "0"
    
    # NUMA optimization
    "kernel.numa_balancing"       = "0"
    
    # Interrupt coalescing
    "net.core.netdev_budget"      = "600"
    "net.core.netdev_budget_usecs" = "8000"
  }

  # CloudWatch alarms configuration
  network_alarms = {
    high_packet_loss = {
      metric_name = "PacketDropCount"
      threshold   = 1000
      period      = 300
      evaluation_periods = 2
      comparison_operator = "GreaterThanThreshold"
    }
    bandwidth_saturation = {
      metric_name = "NetworkBandwidthInGbps"
      threshold   = local.bandwidth_by_instance[var.instance_type] * 0.8
      period      = 300
      evaluation_periods = 2
      comparison_operator = "GreaterThanThreshold"
    }
    efa_errors = {
      metric_name = "EFAPacketDrops"
      threshold   = 100
      period      = 60
      evaluation_periods = 1
      comparison_operator = "GreaterThanThreshold"
    }
    high_latency = {
      metric_name = "NetworkLatency"
      threshold   = local.latency_by_placement[var.placement_strategy] * 2
      period      = 300
      evaluation_periods = 3
      comparison_operator = "GreaterThanThreshold"
    }
  }

  # User data script for EFA and performance optimization
  efa_user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    enable_efa = var.enable_efa
    enable_gdr = var.enable_gdr
    instance_type = var.instance_type
    efa_environment_vars = local.efa_environment_vars
    network_tuning_params = local.network_tuning_params
    enable_jumbo_frames = var.enable_jumbo_frames
    mtu_size = local.mtu_size
    numa_optimization = var.numa_optimization
    custom_user_data = var.user_data_script
  }))

  # FSx for Lustre configuration
  fsx_config = var.enable_fsx_lustre ? {
    storage_capacity = var.fsx_storage_capacity
    deployment_type  = var.fsx_deployment_type
    per_unit_storage_throughput = 1000 # MiB/s per TiB
    subnet_ids = aws_subnet.private_storage[*].id
    security_group_ids = [aws_security_group.fsx.id]
    tags = merge(local.common_tags, {
      Name = "${var.project_name}-fsx-lustre"
      StorageType = "HighPerformance"
    })
  } : null

  # Auto scaling configuration
  asg_config = var.enable_auto_scaling ? {
    min_size = var.min_size
    max_size = var.max_size
    desired_capacity = var.desired_capacity
    health_check_type = "EC2"
    health_check_grace_period = 300
    protect_from_scale_in = false
    target_tracking_scaling_policy = {
      target_value = 70.0
      scale_in_cooldown = 300
      scale_out_cooldown = 300
    }
  } : null
} 