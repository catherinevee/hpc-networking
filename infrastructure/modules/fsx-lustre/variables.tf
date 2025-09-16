# Variables for FSx Lustre Module

variable "name" {
  description = "The name of the FSx Lustre file system"
  type        = string
}

variable "storage_capacity" {
  description = "The storage capacity of the file system in GiB"
  type        = number
  default     = 1200
}

variable "storage_type" {
  description = "The storage type of the file system"
  type        = string
  default     = "SSD"
  validation {
    condition     = contains(["SSD", "HDD"], var.storage_type)
    error_message = "Storage type must be either SSD or HDD."
  }
}

variable "deployment_type" {
  description = "The deployment type of the file system"
  type        = string
  default     = "PERSISTENT_1"
  validation {
    condition     = contains(["PERSISTENT_1", "PERSISTENT_2", "SCRATCH_1", "SCRATCH_2"], var.deployment_type)
    error_message = "Deployment type must be one of: PERSISTENT_1, PERSISTENT_2, SCRATCH_1, SCRATCH_2."
  }
}

variable "per_unit_storage_throughput" {
  description = "The per unit storage throughput in MB/s per TiB"
  type        = number
  default     = 200
}

variable "data_compression_type" {
  description = "The data compression type"
  type        = string
  default     = "LZ4"
  validation {
    condition     = contains(["NONE", "LZ4"], var.data_compression_type)
    error_message = "Data compression type must be either NONE or LZ4."
  }
}

variable "auto_import_policy" {
  description = "The auto import policy"
  type        = string
  default     = "NEW_CHANGED_DELETED"
  validation {
    condition     = contains(["NEW", "NEW_CHANGED", "NEW_CHANGED_DELETED"], var.auto_import_policy)
    error_message = "Auto import policy must be one of: NEW, NEW_CHANGED, NEW_CHANGED_DELETED."
  }
}

variable "automatic_backup_retention_days" {
  description = "The number of days to retain automatic backups"
  type        = number
  default     = 7
}

variable "daily_automatic_backup_start_time" {
  description = "The daily automatic backup start time"
  type        = string
  default     = "03:00"
}

variable "weekly_maintenance_start_time" {
  description = "The weekly maintenance start time"
  type        = string
  default     = "sun:04:00"
}

variable "subnet_ids" {
  description = "The subnet IDs for the file system"
  type        = list(string)
}

variable "security_group_ids" {
  description = "The security group IDs for the file system"
  type        = list(string)
}

variable "data_repository_path" {
  description = "The S3 data repository path"
  type        = string
  default     = null
}

variable "file_system_path" {
  description = "The file system path for data repository association"
  type        = string
  default     = "/"
}

variable "create_mount_target" {
  description = "Whether to create a mount target"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "A map of common tags to assign to the file system"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the file system"
  type        = map(string)
  default     = {}
}
