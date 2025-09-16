# US East 2 Region Configuration for Dev Environment

locals {
  environment = "dev"
  region = "us-east-2"
  
  # Cluster naming convention
  cluster_name = "hpc-${local.environment}"
  
  # Region-specific availability zones
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  
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
      instance_types = ["c5n.9xlarge", "c5n.18xlarge"]
      min_count = 0
      max_count = 500
      spot_percentage = 70
    }
    memory = {
      instance_types = ["r5n.12xlarge", "r5n.24xlarge"]
      min_count = 0
      max_count = 100
      spot_percentage = 50
    }
    gpu = {
      instance_types = ["p3.8xlarge", "p3.16xlarge"]
      min_count = 0
      max_count = 50
      spot_percentage = 60
    }
    debug = {
      instance_types = ["c5n.large", "m5n.large"]
      min_count = 0
      max_count = 10
      spot_percentage = 0
    }
  }
  
  # EFA Configuration
  efa_config = {
    enabled = true
    enable_gpudirect = false  # Disabled for dev
    device_name = "efa0"
    mtu_size = 9000
  }
  
  # Region-specific pricing considerations
  cost_optimization = {
    # us-east-2 has good spot pricing
    spot_percentage = 90
    preferred_spot_types = [
      "c5n.9xlarge",
      "c5n.18xlarge", 
      "r5n.12xlarge",
      "r5n.24xlarge"
    ]
  }
  
  # Region-specific networking
  networking = {
    # Single AZ deployment for minimal latency
    primary_az = "us-east-2a"
    compute_azs = ["us-east-2a"]  # Single AZ for dev
    
    # VPC CIDR for dev (smaller)
    vpc_cidr = "10.0.0.0/16"
    
    # Subnet CIDRs for dev
    subnet_cidrs = {
      public   = ["10.0.1.0/24"]
      private  = ["10.0.10.0/24"]
      compute  = ["10.0.100.0/22"]  # Larger compute subnet
      storage  = ["10.0.200.0/24"]
    }
  }
  
  # VPC configuration for modules
  vpc_config = {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    enable_classiclink = false
    enable_classiclink_dns_support = false
    instance_tenancy = "default"
  }
  
  # Subnet configuration for modules
  subnet_config = {
    public = {
      cidr_blocks = ["10.0.1.0/24"]
      map_public_ip_on_launch = true
      availability_zones = ["us-east-2a"]
    }
    private = {
      cidr_blocks = ["10.0.10.0/24"]
      availability_zones = ["us-east-2a"]
    }
    compute = {
      cidr_blocks = ["10.0.100.0/22"]
      availability_zones = ["us-east-2a"]
    }
    storage = {
      cidr_blocks = ["10.0.200.0/24"]
      availability_zones = ["us-east-2a"]
    }
  }
  
  # Region-specific storage
  storage = {
    # FSx Lustre configuration for us-east-2
    fsx_lustre = {
      scratch = {
        storage_capacity = 50  # TB
        per_unit_storage_throughput = 200  # MB/s per TiB
      }
      persistent = {
        storage_capacity = 10  # TB
        per_unit_storage_throughput = 1000  # MB/s per TiB
      }
    }
    
    # S3 configuration
    s3 = {
      data_repository_bucket = "hpc-data-repository-dev-${local.environment}-${local.region}"
      flow_logs_bucket = "hpc-vpc-flow-logs-dev-${local.environment}-${local.region}"
    }
  }
  
  # FSx Lustre configuration for modules
  fsx_lustre_config = {
    scratch = {
      storage_capacity = 50
      storage_type = "SSD"
      deployment_type = "SCRATCH_1"
      per_unit_storage_throughput = 200
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED"
      automatic_backup_retention_days = 0
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "1:00:00"
      tags = {
        Purpose = "Scratch-Storage"
      }
    }
    persistent = {
      storage_capacity = 10
      storage_type = "SSD"
      deployment_type = "PERSISTENT_1"
      per_unit_storage_throughput = 1000
      data_compression_type = "LZ4"
      auto_import_policy = "NEW_CHANGED"
      automatic_backup_retention_days = 7
      daily_automatic_backup_start_time = "03:00"
      weekly_maintenance_start_time = "1:00:00"
      tags = {
        Purpose = "Persistent-Storage"
      }
    }
  }
  
  # S3 configuration for modules
  s3_config = {
    data_repository = {
      bucket_name = "hpc-data-repository-dev-${local.environment}-${local.region}"
      versioning_enabled = true
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
        }
      ]
      intelligent_tiering = {
        enabled = true
      }
    }
  }
  
  # Region-specific monitoring
  monitoring = {
    # CloudWatch configuration
    cloudwatch = {
      log_retention_days = 7
      detailed_monitoring = false
    }
    
    # Grafana configuration (disabled for dev)
    grafana = {
      enabled = false
    }
    
    # Prometheus configuration
    prometheus = {
      enabled = true
      scrape_interval = "30s"
    }
  }
  
  # CloudWatch configuration for modules
  cloudwatch_config = {
    log_groups = {
      hpc_system_logs = {
        name = "/aws/hpc/${local.environment}/system"
        retention_in_days = 7
      }
      hpc_application_logs = {
        name = "/aws/hpc/${local.environment}/application"
        retention_in_days = 7
      }
    }
    alarms = {
      high_queue_depth = {
        alarm_name = "hpc-${local.environment}-high-queue-depth"
        comparison_operator = "GreaterThanThreshold"
        evaluation_periods = "2"
        metric_name = "JobsQueued"
        namespace = "AWS/ParallelCluster"
        period = "300"
        statistic = "Average"
        threshold = "100"
        alarm_description = "This metric monitors high queue depth"
        treat_missing_data = "notBreaching"
      }
    }
  }
  
  # Region-specific security
  security = {
    # KMS configuration
    kms = {
      key_rotation = true
      multi_region = false
    }
    
    # GuardDuty (disabled for dev)
    guardduty = {
      enabled = false
    }
    
    # Inspector (disabled for dev)
    inspector = {
      enabled = false
    }
    
    # Config (disabled for dev)
    config = {
      enabled = false
    }
  }
  
  # Region-specific compliance
  compliance = {
    # NIST 800-171 (relaxed for dev)
    nist_800_171 = {
      enabled = true
      strict_mode = false
    }
    
    # HIPAA (not required for dev)
    hipaa = {
      enabled = false
    }
    
    # ITAR (not required for dev)
    itar = {
      enabled = false
    }
  }
  
  # Common tags for all resources
  common_tags = {
    Environment = local.environment
    Region = local.region
    Project = "HPC-Networking"
    ManagedBy = "Terragrunt"
    Owner = "DevOps-Team"
  }
}
