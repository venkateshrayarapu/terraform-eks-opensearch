output "dashboard_endpoint" {
  description = "OpenSearch dashboard endpoint"
  value       = "https://${aws_opensearch_domain.main.endpoint}/_dashboards/"
}

output "domain_endpoint" {
  description = "OpenSearch domain endpoint"
  value       = aws_opensearch_domain.main.endpoint
}

output "domain_name" {
  description = "OpenSearch domain name"
  value       = aws_opensearch_domain.main.domain_name
}

output "master_user_arn" {
  description = "ARN of the master user"
  value       = aws_iam_role.opensearch.arn
}

output "security_group_id" {
  description = "ID of the OpenSearch security group"
  value       = aws_security_group.opensearch.id
}
