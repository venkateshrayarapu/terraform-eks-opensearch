variable "project_name" {
  description = "Name of the project"
}

variable "vpc_id" {
  description = "ID of the VPC where EKS cluster will be created"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  type        = string
}