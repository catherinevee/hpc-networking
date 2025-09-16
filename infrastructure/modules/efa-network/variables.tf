# Variables for EFA Network Module

variable "cluster_name" {
  description = "Name of the HPC cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EFA instances will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for EFA network interface"
  type        = string
  default     = null
}

variable "availability_zone" {
  description = "Availability zone for EFA instances"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EFA instances"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "Instance type for EFA instances"
  type        = string
  default     = "c5n.18xlarge"
}

variable "efa_device" {
  description = "EFA device name"
  type        = string
  default     = "efa0"
}

variable "mtu_size" {
  description = "MTU size for EFA network interface"
  type        = number
  default     = 9000
}

variable "enable_gpudirect" {
  description = "Enable GPUDirect RDMA support"
  type        = bool
  default     = false
}

variable "enable_partition_strategy" {
  description = "Enable partition placement group strategy"
  type        = bool
  default     = false
}

variable "partition_count" {
  description = "Number of partitions for placement groups"
  type        = number
  default     = 3
}

variable "root_volume_size" {
  description = "Size of the root volume in GB"
  type        = number
  default     = 100
}

variable "additional_ebs_volumes" {
  description = "Additional EBS volumes to attach"
  type = list(object({
    device_name = string
    volume_type = string
    volume_size = number
    iops        = number
    throughput  = number
  }))
  default = []
}

variable "cpu_core_count" {
  description = "Number of CPU cores"
  type        = number
  default     = null
}

variable "threads_per_core" {
  description = "Number of threads per core"
  type        = number
  default     = 1
}

variable "cpu_credits" {
  description = "CPU credits for burstable instances"
  type        = string
  default     = "standard"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for data access"
  type        = string
  default     = ""
}

variable "private_ips" {
  description = "Private IP addresses for EFA interface"
  type        = list(string)
  default     = []
}

variable "create_efa_interface" {
  description = "Whether to create EFA network interface"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "kms_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "SNS topic ARNs for alarm actions"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "SNS topic ARNs for OK actions"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
