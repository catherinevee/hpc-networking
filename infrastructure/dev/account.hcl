# Dev Environment Account Configuration
locals {
  environment = "dev"
  account_id  = get_aws_account_id()
  region      = "us-east-2"
  
  # Dev-specific configurations
  cluster_capacity = 100
  budget_limit = 50000  # $50,000 per month for dev
  
  # Instance type overrides for dev (smaller instances)
  instance_types = {
    compute = "c5n.9xlarge"  # Smaller than production
    memory  = "r5n.12xlarge"
    gpu     = "p3.8xlarge"
  }
  
  # Storage configuration for dev
  storage_config = {
    fsx_scratch_size = 50    # 50TB instead of 500TB
    fsx_persistent_size = 10 # 10TB instead of 100TB
    s3_intelligent_tiering = false  # Disable for cost savings
  }
  
  # Monitoring configuration for dev
  monitoring_config = {
    log_retention_days = 7    # Shorter retention
    detailed_monitoring = false  # Disable detailed monitoring
    enable_grafana = false    # Disable Grafana for dev
  }
  
  # Security configuration for dev
  security_config = {
    enable_guardduty = false  # Disable for cost savings
    enable_inspector = false
    enable_config = false
  }
  
  # Cost optimization for dev
  cost_optimization = {
    spot_percentage = 90      # Higher spot usage
    enable_savings_plans = false
    enable_reserved_instances = false
  }
}
