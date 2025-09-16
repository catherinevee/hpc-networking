# Variables for ParallelCluster Module

variable "cluster_name" {
  description = "The name of the HPC cluster"
  type        = string
}

variable "create_cluster" {
  description = "Whether to create the cluster"
  type        = bool
  default     = true
}

variable "head_node_instance_type" {
  description = "The instance type for the head node"
  type        = string
  default     = "c5n.2xlarge"
}

variable "subnet_id" {
  description = "The subnet ID for the cluster"
  type        = string
}

variable "security_group_ids" {
  description = "The security group IDs for the cluster"
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to the cluster"
  type        = map(string)
  default     = {}
}
