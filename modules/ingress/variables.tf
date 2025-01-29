variable "dashboard_domain" {
  description = "Domain name for OpenSearch Dashboard"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ingress controller will be deployed"
  type        = string
}

variable "opensearch_cluster_name" {
  description = "Name of the OpenSearch cluster"
  type        = string
}
