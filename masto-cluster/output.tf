output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.mastodon.name
}

output "cluster_id" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.mastodon.id
}

output "load_balancer_dns" {
  description = "Load balancer DNS name"
  value       = aws_lb.masto_lb.dns_name
}

output "elasticache_endpoint" {
  description = "Elasticache endpoint"
  value       = aws_elasticache_cluster.mastodon.cache_nodes.0.address
}

output "load_balancer_zone_id" {
  description = "Load balancer zone ID"
  value       = aws_lb.masto_lb.zone_id
}

output "vapid_public_key_pem" {
  description = "Vapid public key"
  value       = tls_private_key.mastodon_vapid.public_key_pem
}

output "vapid_public_key_openssh" {
  description = "Vapid public key in OpenSSH format"
  value       = tls_private_key.mastodon_vapid.public_key_openssh
}
