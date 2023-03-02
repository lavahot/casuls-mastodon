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
      cidr      = ["0.0.0.0/0"]
    }
    ecs_tasks_https = {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      type      = ["ingress"]
      cidr      = ["0.0.0.0/0"]
    }
    ecs_tasks_redis = {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      type                     = ["egress"]
      source_security_group_id = aws_security_group.elasticache_sg.id
    }
    ecs_tasks_s3 = {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      type      = ["egress"]
      cidr      = ["0.0.0.0/0"]
    }
    ecs_tasks_efs = {
      from_port                = 2049
      to_port                  = 2049
      protocol                 = "tcp"
      type                     = ["egress"]
      source_security_group_id = aws_security_group.efs_sg.id
    }
    ecs_tasks_efs_secure = {
      from_port                = 2999
      to_port                  = 2999
      protocol                 = "tcp"
      type                     = ["egress"]
      source_security_group_id = aws_security_group.efs_sg.id
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
        type                     = type
        from_port                = port.from_port
        to_port                  = port.to_port
        protocol                 = port.protocol
        cidr                     = lookup(port, "cidr", null)
        source_security_group_id = lookup(port, "source_security_group_id", null)
      }
    }
  ]])
}


resource "aws_security_group_rule" "mastodon_sg" {
  for_each = { for port in local.flattened_ports : port.key => port.value }

  description              = each.key
  type                     = each.value.type
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.ecs_tasks.id
  cidr_blocks              = each.value.cidr
  source_security_group_id = each.value.source_security_group_id

}

resource "aws_security_group_rule" "outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# A security group that allows inbound communication from the alb to the ecs tasks
resource "aws_security_group_rule" "inbound" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_tasks.id
  source_security_group_id = aws_security_group.lb_sg.id
}
