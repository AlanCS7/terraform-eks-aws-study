variable "prefix" {
  type        = string
  description = "Prefix for all resources"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "retention_in_days" {
  type        = number
  description = "Retention period for CloudWatch logs"
  default     = 30
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired size for the node group"
  default     = 2
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum size for the node group"
  default     = 4
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum size for the node group"
  default     = 2
}
