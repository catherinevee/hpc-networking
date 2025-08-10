# High-Performance Networking Module Variables
# Optimized for AI/ML workloads with EFA, InfiniBand, and RDMA support

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "hpc-networking"
  
  validation {
    condition = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition = contains([
      "us-east-1", "us-west-2", "us-west-1", "eu-west-1", 
      "eu-central-1", "ap-southeast-1", "ap-northeast-1"
    ], var.region)
    error_message = "Region must be a supported region for high-performance networking."
  }
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
  
  validation {
    condition = can(regex("^vpc-[a-z0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid VPC identifier."
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid CIDR block."
  }
}

# Instance Configuration
variable "instance_type" {
  description = "EC2 instance type for high-performance computing"
  type        = string
  default     = "p5.48xlarge"
  
  validation {
    condition = contains([
      # P5 series - 3rd gen EFA, up to 3,200 Gbps
      "p5.48xlarge", "p5.24xlarge", "p5.12xlarge",
      # P4 series - 2nd gen EFA, up to 400 Gbps  
      "p4d.24xlarge", "p4de.24xlarge", "p4d.24xlarge",
      # G5 series - 1st gen EFA, up to 100 Gbps
      "g5.48xlarge", "g5.24xlarge", "g5.12xlarge",
      # C6i series - CPU optimized with EFA
      "c6i.32xlarge", "c6i.24xlarge", "c6i.16xlarge"
    ], var.instance_type)
    error_message = "Instance type must support EFA for high-performance networking."
  }
}

variable "instance_count" {
  description = "Number of instances in the cluster"
  type        = number
  default     = 8
  
  validation {
    condition = var.instance_count >= 1 && var.instance_count <= 64
    error_message = "Instance count must be between 1 and 64."
  }
}

# Networking Configuration
variable "enable_efa" {
  description = "Enable Elastic Fabric Adapter (EFA)"
  type        = bool
  default     = true
}

variable "enable_gdr" {
  description = "Enable GPU Direct RDMA (GPUDirect)"
  type        = bool
  default     = true
}

variable "placement_strategy" {
  description = "Placement group strategy for low latency"
  type        = string
  default     = "cluster"
  
  validation {
    condition = contains(["cluster", "partition", "spread"], var.placement_strategy)
    error_message = "Valid strategies: cluster (low latency), partition (large scale), spread (fault isolation)."
  }
}

variable "subnet_configuration" {
  description = "Subnet configuration for different tiers"
  type = object({
    public_subnets = list(string)
    private_compute_subnets = list(string)
    private_storage_subnets = list(string)
    private_endpoint_subnets = list(string)
  })
  default = {
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
    private_compute_subnets = ["10.0.10.0/22", "10.0.14.0/22"]
    private_storage_subnets = ["10.0.20.0/24", "10.0.21.0/24"]
    private_endpoint_subnets = ["10.0.30.0/24", "10.0.31.0/24"]
  }
  
  validation {
    condition = alltrue([
      for cidr in var.subnet_configuration.public_subnets : can(cidrhost(cidr, 0))
    ]) && alltrue([
      for cidr in var.subnet_configuration.private_compute_subnets : can(cidrhost(cidr, 0))
    ]) && alltrue([
      for cidr in var.subnet_configuration.private_storage_subnets : can(cidrhost(cidr, 0))
    ]) && alltrue([
      for cidr in var.subnet_configuration.private_endpoint_subnets : can(cidrhost(cidr, 0))
    ])
    error_message = "All subnet CIDR blocks must be valid."
  }
}

# Storage Configuration
variable "enable_fsx_lustre" {
  description = "Enable FSx for Lustre with GPUDirect Storage"
  type        = bool
  default     = true
}

variable "fsx_storage_capacity" {
  description = "FSx for Lustre storage capacity in GB"
  type        = number
  default     = 14400 # 14.4TB
  
  validation {
    condition = var.fsx_storage_capacity >= 1200 && var.fsx_storage_capacity <= 100000
    error_message = "FSx storage capacity must be between 1.2TB and 100TB."
  }
}

variable "fsx_deployment_type" {
  description = "FSx for Lustre deployment type"
  type        = string
  default     = "PERSISTENT_2"
  
  validation {
    condition = contains(["PERSISTENT_2", "SCRATCH_2"], var.fsx_deployment_type)
    error_message = "Deployment type must be PERSISTENT_2 or SCRATCH_2."
  }
}

# Security Configuration
variable "enable_vpc_endpoints" {
  description = "Enable VPC endpoints for cost optimization"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the cluster"
  type        = list(string)
  default     = ["10.0.0.0/16"]
  
  validation {
    condition = alltrue([
      for cidr in var.allowed_cidr_blocks : can(cidrhost(cidr, 0))
    ])
    error_message = "All allowed CIDR blocks must be valid."
  }
}

variable "enable_encryption" {
  description = "Enable encryption at rest and in transit"
  type        = bool
  default     = true
}

# Cost Optimization
variable "allow_spot_instances" {
  description = "Allow spot instances for cost optimization"
  type        = bool
  default     = false
}

variable "spot_max_price" {
  description = "Maximum spot instance price (percentage of on-demand)"
  type        = string
  default     = "90"
  
  validation {
    condition = can(regex("^[0-9]+$", var.spot_max_price)) && tonumber(var.spot_max_price) <= 100
    error_message = "Spot max price must be a number between 0 and 100."
  }
}

# Monitoring Configuration
variable "enable_cloudwatch" {
  description = "Enable CloudWatch monitoring and alerting"
  type        = bool
  default     = true
}

variable "cloudwatch_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
  
  validation {
    condition = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.cloudwatch_retention_days)
    error_message = "CloudWatch retention must be a valid retention period."
  }
}

# Performance Tuning
variable "enable_jumbo_frames" {
  description = "Enable jumbo frames (9001 MTU) for high bandwidth"
  type        = bool
  default     = true
}

variable "enable_sriov" {
  description = "Enable SR-IOV for enhanced networking"
  type        = bool
  default     = true
}

variable "numa_optimization" {
  description = "Enable NUMA optimization for multi-socket systems"
  type        = bool
  default     = true
}

# Tags
variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.tags : 
        can(regex("^[a-zA-Z0-9_.-]+$", key)) && 
        length(value) <= 256
    ])
    error_message = "Tag keys must be alphanumeric with dots, underscores, or hyphens. Tag values must be 256 characters or less."
  }
}

# Advanced Configuration
variable "user_data_script" {
  description = "Custom user data script for instance initialization"
  type        = string
  default     = ""
  sensitive   = true
}

variable "iam_instance_profile" {
  description = "IAM instance profile for EC2 instances"
  type        = string
  default     = ""
  
  validation {
    condition = var.iam_instance_profile == "" || can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.iam_instance_profile))
    error_message = "IAM instance profile name must be valid."
  }
}

variable "key_name" {
  description = "SSH key pair name for instance access"
  type        = string
  default     = ""
  sensitive   = true
  
  validation {
    condition = var.key_name == "" || can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.key_name))
    error_message = "SSH key name must be valid."
  }
}

# Scaling Configuration
variable "enable_auto_scaling" {
  description = "Enable auto scaling for the cluster"
  type        = bool
  default     = false
}

variable "min_size" {
  description = "Minimum number of instances in auto scaling group"
  type        = number
  default     = 1
  
  validation {
    condition = var.min_size >= 1
    error_message = "Minimum size must be at least 1."
  }
}

variable "max_size" {
  description = "Maximum number of instances in auto scaling group"
  type        = number
  default     = 64
  
  validation {
    condition = var.max_size >= var.min_size
    error_message = "Maximum size must be greater than or equal to minimum size."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in auto scaling group"
  type        = number
  default     = 8
  
  validation {
    condition = var.desired_capacity >= var.min_size && var.desired_capacity <= var.max_size
    error_message = "Desired capacity must be between minimum and maximum size."
  }
} 