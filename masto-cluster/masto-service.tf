# ECS security group

resource "aws_security_group" "ecs_tasks" {
  name        = format("%s-ecs-tasks-sg", local.cluster_name)
  description = format("Security Group for ECS Task cluster %s", local.cluster_name)
  vpc_id      = var.vpc_id
}

resource "aws_ecs_service" "mastodon" {
  name            = "mastodon"
  cluster         = aws_ecs_cluster.mastodon.id
  task_definition = aws_ecs_task_definition.mastodon_service.id
  desired_count   = 1
  #   iam_role        = aws_iam_role.mastodon_manager.arn
  #   depends_on      = [aws_iam_role_policy.foo]


  #   load_balancer {
  #     target_group_arn = aws_lb_target_group.foo.arn
  #     container_name   = "mastodon"
  #     container_port   = 8080
  #   }

  network_configuration {
    subnets          = [var.public_subnet_id, var.private_subnet_id]
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  #  Not allowed on Fargate
  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }
}

resource "aws_ecs_task_definition" "mastodon_service" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 2048
  container_definitions = jsonencode([
    {
      name  = "mastodon"
      image = "linuxserver/mastodon:4.1.0"
    }
  ])
}
