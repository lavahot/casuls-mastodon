# output "cluster_id" {
#   description = "EKS cluster ID"
#   value       = module.eks.cluster_id
# }

# output "cluster_endpoint" {
#   description = "Endpoint for EKS control plane"
#   value       = module.eks.cluster_endpoint
# }

# output "cluster_security_group_id" {
#   description = "Security group ids attached to the cluster control plane"
#   value       = module.eks.cluster_security_group_id
# }

output "region" {
  description = "AWS region"
  value       = var.region
}

# output "cluster_name" {
#   description = "Kubernetes Cluster Name"
#   value       = local.cluster_name
# }

output "cluster_name" {
  description = "ECS cluster name"
  value       = module.mastodon_cluster.cluster_name
}

output "cluster_id" {
  description = "ECS cluster ARN"
  value       = module.mastodon_cluster.cluster_id
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = module.mastodon_cluster.load_balancer_dns
}

output "elasticache_endpoint" {
  description = "Elasticache endpoint"
  value       = module.mastodon_cluster.elasticache_endpoint
}

output "nameservers" {
  description = "Nameservers for the domain"
  value       = module.domain.nameservers
}
