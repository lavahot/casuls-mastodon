output "cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.mastodon.name
}

output "cluster_id" {
  description = "ECS cluster ARN"
  value       = aws_ecs_cluster.mastodon.id
}
