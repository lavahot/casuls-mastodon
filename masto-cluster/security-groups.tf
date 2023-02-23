resource "aws_security_group" "ecs_tasks" {
  name        = format("%s-ecs-tasks-sg", local.cluster_name)
  description = format("Security Group for ECS Task cluster %s", local.cluster_name)
  vpc_id      = var.vpc_id
}

# Write a terraform loop that creates security groups that allows the container to connect to RDS, Elasticache Redis, S3, EFS, and Cloudwatch.
locals {
  ecs_tasks_ports = {
    ecs_tasks_http = {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
      type      = ["ingress"]
    }
    ecs_tasks_https = {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      type      = ["ingress"]
    }
    ecs_tasks_redis = {
      from_port = 6379
      to_port   = 6379
      protocol  = "tcp"
      type      = ["egress"]
    }
    # ecs_tasks_s3 = {
    #   from_port = 443
    #   to_port   = 443
    #   protocol  = "tcp"
    #   type      = ["egress"]
    # }
    ecs_tasks_efs = {
      from_port = 2049
      to_port   = 2049
      protocol  = "tcp"
      type      = ["egress"]
    }
    # ecs_tasks_cloudwatch = {
    #   from_port = 443
    #   to_port   = 443
    #   protocol  = "tcp"
    #   type      = ["egress"]
    # }
  }
  flattened_ports = flatten([for port_key, port in local.ecs_tasks_ports : [
    for type in port.type : {
      key = "${port_key}-${type}"
      value = {
        type      = type
        from_port = port.from_port
        to_port   = port.to_port
        protocol  = port.protocol
      }
    }
  ]])
}


resource "aws_security_group_rule" "mastodon_sg" {
  for_each = { for port in local.flattened_ports : port.key => port.value }

  description       = each.key
  type              = each.value.type
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.ecs_tasks.id
  self              = true
  # cidr_blocks       = [var.vpc_cidr_block]

}

resource "aws_security_group_rule" "outbound" {
  type      = "egress"
  from_port = 0
  to_port   = 0
  protocol  = "-1"
  # self              = true
  security_group_id = aws_security_group.ecs_tasks.id
  # source_security_group_id = aws_security_group.ecs_tasks.id
  # cidr_blocks              = [var.vpc_cidr_block]
  cidr_blocks = ["0.0.0.0/0"]
}