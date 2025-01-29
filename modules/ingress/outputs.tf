output "ingress_security_group_id" {
  description = "ID of the security group created for the ingress controller"
  value       = aws_security_group.ingress.id
}

output "load_balancer_hostname" {
  description = "Hostname of the load balancer"
  value       = try(kubernetes_ingress_v1.opensearch_dashboard_ingress.status[0].load_balancer[0].ingress[0].hostname, "")
}
