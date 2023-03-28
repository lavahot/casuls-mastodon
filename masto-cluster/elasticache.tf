# Make a cloudwatch log group for the elasticache cluster

resource "aws_cloudwatch_log_group" "elasticache" {
  name              = "/elasticache/mastodon"
  retention_in_days = 30
}

# Create an elasticache cluster

resource "aws_elasticache_cluster" "mastodon" {
  cluster_id         = "mastodon"
  engine             = "redis"
  node_type          = "cache.t2.micro"
  num_cache_nodes    = 1
  port               = 6379
  subnet_group_name  = length(var.elasticache_subnet_group_name) > 0 ? var.elasticache_subnet_group_name : aws_elasticache_subnet_group.elasticache_subnet_group.0.name
  security_group_ids = [aws_security_group.elasticache_sg.id]
  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.elasticache.name
    destination_type = "cloudwatch-logs"
    log_format       = "text"
    log_type         = "engine-log"
  }
  apply_immediately = true
}

# Create a security group for the elasticache cluster

resource "aws_security_group" "elasticache_sg" {
  name        = "elasticache_sg"
  description = "Security group for the elasticache cluster"
  vpc_id      = var.vpc_id
}

# Create a security group rule for the elasticache cluster that allows incoming connections from the ecs security group

resource "aws_security_group_rule" "elasticache_sg" {
  type                     = "ingress"
  from_port                = aws_elasticache_cluster.mastodon.cache_nodes.0.port
  to_port                  = aws_elasticache_cluster.mastodon.cache_nodes.0.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elasticache_sg.id
  source_security_group_id = aws_security_group.ecs_tasks.id
}


# Create a subnet group for the elasticache cluster if not passed in by VPC module

resource "aws_elasticache_subnet_group" "elasticache_subnet_group" {
  count       = length(var.elasticache_subnet_group_name) > 0 ? 0 : 1
  name        = "elasticache_subnet_group"
  description = "Subnet group for the elasticache cluster"
  subnet_ids  = var.private_subnet_ids
}
