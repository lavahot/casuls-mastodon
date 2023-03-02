# Create role for task to use to interact with AWS APIs

resource "aws_iam_role" "mastodon_task" {
  name = "mastodon_task"

  assume_role_policy = data.aws_iam_policy_document.assume_role_pd.json

}

resource "aws_iam_role_policy_attachment" "fargate_cw_emitter" {
  role       = aws_iam_role.fargate_runner.name
  policy_arn = aws_iam_policy.cw_emitter.arn
}

resource "aws_iam_role_policy_attachment" "masto_cw" {
  role       = aws_iam_role.mastodon_task.name
  policy_arn = aws_iam_policy.cw_emitter.arn
}

# Add ecr permissions to fargate runner

data "aws_iam_policy_document" "ecr_image_getter" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:sourceVpce"
    #   values   = [module.vpc_endpoints.endpoints["ecr"].id]
    # }
    condition {
      test     = "StringEquals"
      variable = "aws:sourceVpc"
      values   = [var.vpc_id]
    }
  }
}

resource "aws_iam_policy" "ecr_image_getter" {
  name = "ecrImageGetter"

  policy = data.aws_iam_policy_document.ecr_image_getter.json
}

resource "aws_iam_role_policy_attachment" "fr_ecr_pa" {
  role       = aws_iam_role.fargate_runner.name
  policy_arn = aws_iam_policy.ecr_image_getter.arn
}

# Mastodon ECS service definition

resource "aws_ecs_service" "mastodon" {
  name                = "mastodon"
  cluster             = aws_ecs_cluster.mastodon.id
  task_definition     = aws_ecs_task_definition.mastodon_service.id
  desired_count       = 1
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"
  depends_on = [
    aws_iam_role.mastodon_task,
    aws_iam_role_policy_attachment.masto_cw,
  ]


  load_balancer {
    target_group_arn = aws_lb_target_group.masto_tg.arn
    container_name   = "mastodon"
    container_port   = 80
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Mastodon ECS task to run in the Mastodon service

data "aws_region" "current" {}

locals {
  params = {
    puid         = 1000
    pgid         = 1000
    tz           = "America / New_York"
    local_domain = var.domain_name
    # TODO: fix this to connect to the instance in the same az when scaling redis
    redis_host = aws_elasticache_cluster.mastodon.cache_nodes.0.address
    redis_port = aws_elasticache_cluster.mastodon.cache_nodes.0.port
    db_host    = aws_rds_cluster.rds_cluster.endpoint
    db_user    = aws_rds_cluster.rds_cluster.master_username
    db_pass    = aws_rds_cluster.rds_cluster.master_password
    db_name    = aws_rds_cluster.rds_cluster.database_name
    db_port    = aws_rds_cluster.rds_cluster.port
    es_enabled = false
    # secret_key_base   = random_string.mastodon_secret_key.result
    # otp_secret        = random_string.mastodon_otp_secret.result
    # vapid_private_key = random_string.mastodon_vapid_private_key.result
    # vapid_public_key  = random_string.mastodon_vapid_public_key.result
    # smtp_server       = ""
    # smtp_port         = 25
    # smtp_login        = ""
    # smtp_password     = ""
    smtp_from_address = "notifications@${var.domain_name}"
    s3_enabled        = true
    s3_bucket         = aws_s3_bucket.mastodon_media.bucket_domain_name
  }
  folded_params = [for k, v in local.params : { name = upper(k), value = tostring(v) }]
}

resource "aws_ecs_task_definition" "mastodon_service" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  task_role_arn            = aws_iam_role.mastodon_task.arn
  execution_role_arn       = aws_iam_role.fargate_runner.arn

  container_definitions = jsonencode([
    {
      name  = "mastodon"
      image = "linuxserver/mastodon:4.1.0"
      # image       = "nginxdemos/hello"
      networkMode = "awsvpc"
      environment = local.folded_params
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
        {
          containerPort = 443
          hostPort      = 443
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          # aws-logs-create-group = "true"
          awslogs-group         = aws_cloudwatch_log_group.mastodon_cw_group.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "mastodon"
        }
      }
    }
  ])

  volume {
    name = "mastodon-storage"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.mastofs.id
      root_directory          = "/config"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.masto_fs_ap.id
        iam             = "ENABLED"
      }
    }
  }

}
