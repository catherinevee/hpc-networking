# Dev Environment Configuration

# Consolidated Configuration for Dev Environment
locals {
  environment = "dev"
  region = "us-east-2"  # Default region, can be overridden in region.hcl
  
  # Cluster naming convention
  cluster_name = "hpc-${local.environment}"
  
  # Instance type mappings for different workloads
  instance_types = {
    compute = {
      hpc_optimized = "hpc6a.48xlarge"  # 96 vCPUs, 384 GiB RAM, 100 Gbps EFA
      memory_optimized = "x2iezn.32xlarge"  # 128 vCPUs, 4 TiB RAM
      gpu_instances = "p4d.24xlarge"  # 8x A100 GPUs
      general_purpose = "m6i.32xlarge"  # 128 vCPUs, 512 GiB RAM
    }
    spot_types = [
      "hpc6a.48xlarge",
      "c5n.18xlarge",
      "c5n.24xlarge",
      "c5n.9xlarge",
      "m5n.24xlarge",
      "m5dn.24xlarge"
    ]
  }
  
  # Queue configurations for Slurm
  slurm_queues = {
    compute = {
      instance_types = ["hpc6a.48xlarge", "c5n.18xlarge"]
      min_count = 0
      max_count = 500
      spot_percentage = 70
    }
    memory = {
      instance_types = ["x2iezn.32xlarge", "r5n.24xlarge"]
      min_count = 0
      max_count = 100
      spot_percentage = 50
    }
    gpu = {
      instance_types = ["p4d.24xlarge", "p3.16xlarge"]
      min_count = 0
      max_count = 50
      spot_percentage = 60
    }
    debug = {
      instance_types = ["c5n.large", "m5n.large"]
      min_count = 1
      max_count = 10
      spot_percentage = 0
    }
  }
  
  # EFA configuration
  efa_config = {
    enabled = true
    instance_types = local.instance_types.spot_types
    security_group_rules = {
      efa_ports = {
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        description = "EFA communication"
      }
      mpi_ports = {
        from_port = 1024
        to_port = 65535
        protocol = "tcp"
        description = "MPI communication"
      }
    }
  }
  
  # Placement group configuration
  placement_groups = {
    compute = {
      strategy = "cluster"
      partition_count = 3
    }
    storage = {
      strategy = "partition"
      partition_count = 2
    }
  }
  
  # Auto-scaling configuration
  auto_scaling = {
    scale_down_cooldown = 300  # 5 minutes
    scale_up_cooldown = 60     # 1 minute
    max_nodes_per_az = 100
    min_nodes_per_az = 0
    target_capacity = 80  # percentage
  }
  
  # VPC Configuration
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    enable_classiclink = false
    enable_classiclink_dns_support = false
    instance_tenancy = "default"
  }
  
  # Subnet Configuration
  subnet_config = {
    public = {
      cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
      map_public_ip_on_launch = true
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    private = {
      cidr_blocks = ["10.0.10.0/24", "10.0.20.0/24", "10.0.30.0/24"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    compute = {
      cidr_blocks = ["10.0.100.0/22", "10.0.104.0/22", "10.0.108.0/22"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
    storage = {
      cidr_blocks = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]
      map_public_ip_on_launch = false
      availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
    }
  }
  
  # Security Group Rules
  security_groups = {
    # EFA Security Group for MPI communication
    efa = {
      name = "hpc-efa-sg"
      description = "Security group for EFA-enabled instances"
      ingress_rules = [
        {
          from_port = 2049
          to_port = 2049
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "EFA communication"
        },
        {
          from_port = 1024
          to_port = 65535
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "MPI communication"
        },
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          self = true
          description = "All traffic within security group"
        }
      ]
      egress_rules = [
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All outbound traffic"
        }
      ]
    }
    
    # Head Node Security Group
    head_node = {
      name = "hpc-head-node-sg"
      description = "Security group for Slurm head node"
      ingress_rules = [
        {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
          description = "SSH access"
        },
        {
          from_port = 6817
          to_port = 6817
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Slurm controller"
        },
        {
          from_port = 6818
          to_port = 6818
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Slurm database"
        },
        {
          from_port = 8080
          to_port = 8080
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Open OnDemand"
        }
      ]
    }
    
    # Compute Node Security Group
    compute_node = {
      name = "hpc-compute-node-sg"
      description = "Security group for compute nodes"
      ingress_rules = [
        {
          from_port = 22
          to_port = 22
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "SSH access from head node"
        },
        {
          from_port = 0
          to_port = 0
          protocol = "-1"
          source_security_group_id = "hpc-efa-sg"
          description = "All traffic from EFA security group"
        }
      ]
    }
    
    # Storage Security Group
    storage = {
      name = "hpc-storage-sg"
      description = "Security group for storage systems"
      ingress_rules = [
        {
          from_port = 2049
          to_port = 2049
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "NFS access"
        },
        {
          from_port = 111
          to_port = 111
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "RPC portmapper"
        },
        {
          from_port = 20048
          to_port = 20048
          protocol = "tcp"
          cidr_blocks = [local.vpc_config.cidr_block]
          description = "Lustre MGS"
        }
      ]
    }
  }
  
  # FSx Lustre Configuration
  fsx_lustre_config = {
    # Scratch filesystem for temporary data
    scratch = {
      storage_capacity = 50  # TB (reduced for dev)
      storage_type = "SSD"
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 200  # MB/s per TiB
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED_DELETED"
      automatic_backup_retention_days = 7
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "sun:04:00"
      tags = {
        Purpose = "Scratch-Storage"
        Environment = local.environment
        DataLifecycle = "Temporary"
      }
    }
    
    # Persistent filesystem for long-term data
    persistent = {
      storage_capacity = 10  # TB (reduced for dev)
      storage_type = "SSD"
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 1000  # MB/s per TiB
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED_DELETED"
      automatic_backup_retention_days = 30
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "sun:04:00"
      tags = {
        Purpose = "Persistent-Storage"
        Environment = local.environment
        DataLifecycle = "Long-term"
      }
    }
  }
  
  # S3 Configuration for data repository
  s3_config = {
    data_repository = {
      bucket_name = "hpc-data-repository-${local.environment}-${local.region}"
      versioning_enabled = true
      encryption_enabled = true
      encryption_algorithm = "AES256"
      lifecycle_rules = [
        {
          id = "transition_to_ia"
          enabled = true
          transition = [
            {
              days = 30
              storage_class = "STANDARD_IA"
            }
          ]
        },
        {
          id = "transition_to_glacier"
          enabled = true
          transition = [
            {
              days = 90
              storage_class = "GLACIER"
            }
          ]
        }
      ]
      intelligent_tiering = {
        enabled = true
        status = "Enabled"
      }
    }
    
    # S3 bucket for VPC Flow Logs
    flow_logs = {
      bucket_name = "hpc-vpc-flow-logs-${local.environment}-${local.region}"
      versioning_enabled = true
      encryption_enabled = true
      lifecycle_rules = [
        {
          id = "delete_old_logs"
          enabled = true
          expiration = {
            days = 90
          }
        }
      ]
    }
    
    # S3 bucket for CloudWatch Logs
    cloudwatch_logs = {
      bucket_name = "hpc-cloudwatch-logs-${local.environment}-${local.region}"
      versioning_enabled = true
      encryption_enabled = true
      lifecycle_rules = [
        {
          id = "transition_to_ia"
          enabled = true
          transition = [
            {
              days = 30
              storage_class = "STANDARD_IA"
            }
          ]
        },
        {
          id = "delete_old_logs"
          enabled = true
          expiration = {
            days = 365
          }
        }
      ]
    }
  }
  
  # CloudWatch Configuration
  cloudwatch_config = {
    log_groups = {
      hpc_system_logs = {
        name = "/aws/hpc/${local.environment}/system"
        retention_in_days = 7  # Reduced for dev
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      slurm_logs = {
        name = "/aws/hpc/${local.environment}/slurm"
        retention_in_days = 30  # Reduced for dev
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      mpi_logs = {
        name = "/aws/hpc/${local.environment}/mpi"
        retention_in_days = 7  # Reduced for dev
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      application_logs = {
        name = "/aws/hpc/${local.environment}/applications"
        retention_in_days = 30  # Reduced for dev
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
      vpc_flow_logs = {
        name = "/aws/vpc/flowlogs/${local.environment}"
        retention_in_days = 7  # Reduced for dev
        kms_key_id = "alias/hpc-cloudwatch-key"
      }
    }
    
    # Custom metrics for HPC workloads
    custom_metrics = {
      job_efficiency = {
        namespace = "HPC/Jobs"
        metric_name = "JobEfficiency"
        statistic = "Average"
        period = 300  # 5 minutes
        unit = "Percent"
      }
      mpi_latency = {
        namespace = "HPC/Network"
        metric_name = "MPILatency"
        statistic = "Average"
        period = 60  # 1 minute
        unit = "Microseconds"
      }
      storage_throughput = {
        namespace = "HPC/Storage"
        metric_name = "StorageThroughput"
        statistic = "Sum"
        period = 60  # 1 minute
        unit = "Bytes/Second"
      }
      queue_depth = {
        namespace = "HPC/Scheduler"
        metric_name = "QueueDepth"
        statistic = "Maximum"
        period = 60  # 1 minute
        unit = "Count"
      }
      node_utilization = {
        namespace = "HPC/Compute"
        metric_name = "NodeUtilization"
        statistic = "Average"
        period = 300  # 5 minutes
        unit = "Percent"
      }
    }
  }
  
  # Dev-specific overrides
  cluster_capacity = 100
  cloudwatch_log_retention_days = 7
  enable_detailed_monitoring = false
  enable_grafana = false
  enable_guardduty = false
  enable_inspector = false
  enable_config = false
  spot_instance_percentage = 90
  enable_savings_plans = false
  enable_reserved_instances = false
  
  # Dev-specific tags
  common_tags = {
    Environment = "dev"
    CostCenter  = "HPC-Dev"
    Owner       = "HPC-Team"
    Project     = "HPC-Networking"
    ManagedBy   = "Terragrunt"
  }
}
