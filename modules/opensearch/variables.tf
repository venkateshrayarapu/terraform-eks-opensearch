variable "domain_name" {
  description = "OpenSearch domain name"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "instance_type" {
  description = "Instance type for OpenSearch nodes"
}

variable "instance_count" {
  description = "Number of OpenSearch nodes"
  type        = number
}

variable "eks_security_group_id" {
  description = "Security group ID of the EKS cluster"
}

variable "bastion_security_group_id" {
  description = "Security group ID of the bastion host"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
}