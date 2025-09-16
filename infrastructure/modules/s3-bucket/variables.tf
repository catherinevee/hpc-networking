# Variables for S3 Bucket Module

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Whether to enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "encryption_enabled" {
  description = "Whether to enable server-side encryption"
  type        = bool
  default     = true
}

variable "encryption_algorithm" {
  description = "The server-side encryption algorithm"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either AES256 or aws:kms."
  }
}

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket"
  type = list(object({
    id                             = string
    enabled                        = bool
    transition                     = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    expiration                     = optional(object({
      days = number
    }), null)
    noncurrent_version_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    noncurrent_version_expiration  = optional(object({
      days = number
    }), null)
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to assign to the bucket"
  type        = map(string)
  default     = {}
}
