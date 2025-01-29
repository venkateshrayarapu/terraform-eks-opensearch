# OpenSearch Outputs
output "opensearch_dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = module.opensearch.dashboard_endpoint
}

output "opensearch_domain_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = module.opensearch.domain_endpoint
}

output "opensearch_domain_name" {
  description = "OpenSearch domain name"
  value       = module.opensearch.domain_name
}

output "opensearch_master_user_arn" {
  description = "ARN of the OpenSearch master user"
  value       = module.opensearch.master_user_arn
}

# EKS Outputs
output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = var.project_name
}

output "eks_cluster_certificate_authority" {
  description = "EKS cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

# Bastion Host Output
output "bastion_public_ip" {
  description = "Public IP of the bastion host"
  value       = module.vpc.bastion_public_ip
}
