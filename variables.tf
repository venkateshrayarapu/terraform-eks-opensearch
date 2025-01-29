variable "aws_region" {
  description = "AWS region"
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  default     = "opensearch-eks"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "node_instance_type" {
  description = "Instance type for EKS nodes"
  default     = "t3.medium"
}

variable "domain_name" {
  description = "OpenSearch domain name"
  default     = "opensearch-cluster"
}

variable "opensearch_instance_type" {
  description = "Instance type for OpenSearch nodes"
  default     = "t3.medium.search"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  default     = "dev"
}