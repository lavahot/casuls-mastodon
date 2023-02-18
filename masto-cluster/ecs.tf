resource "aws_ecs_cluster" "mastodon" {
  name = "mastodon"
}

# Replace this with an EC2-based capacity provider
resource "aws_ecs_cluster_capacity_providers" "fargate_provider" {
  cluster_name = aws_ecs_cluster.mastodon.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}
