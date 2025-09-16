# US East 2 Region Configuration for Dev Environment

locals {
  region = "us-east-2"
  
  # Region-specific availability zones
  availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  
  # Region-specific instance types (optimized for us-east-2)
  instance_types = {
    compute = "c5n.9xlarge"
    memory  = "r5n.12xlarge"
    gpu     = "p3.8xlarge"
    debug   = "c5n.large"
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
      data_repository_bucket = "hpc-data-repository-dev-${random_id.bucket_suffix.hex}"
      flow_logs_bucket = "hpc-vpc-flow-logs-dev-${random_id.bucket_suffix.hex}"
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
}
