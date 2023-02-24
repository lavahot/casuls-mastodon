resource "aws_efs_file_system" "mastodon_efs" {
  tags = {}
}

resource "aws_efs_access_point" "mastodon_efs_ap" {
  file_system_id = aws_efs_file_system.mastodon_efs.id
}


# FARGATE IAM permissions

data "aws_iam_policy_document" "ecs_task_execution" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role_pd" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "fargate_runner" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = data.aws_iam_policy_document.assume_role_pd.json
}

# Create role for task to use to interact with AWS APIs

resource "aws_iam_role" "mastodon_task" {
  name = "mastodon_task"

  assume_role_policy = data.aws_iam_policy_document.assume_role_pd.json

}

# Add cloud logging permissions

data "aws_iam_policy_document" "cw_emitter" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      # "elasticfilesystem:CreateFileSystem",
      # "elasticfilesystem:CreateMountTarget",
      # "elasticfilesystem:CreateTags",
      # "elasticfilesystem:CreateAccessPoint",
      # "elasticfilesystem:CreateReplicationConfiguration",
      # "elasticfilesystem:DeleteFileSystem",
      # "elasticfilesystem:DeleteMountTarget",
      # "elasticfilesystem:DeleteTags",
      # "elasticfilesystem:DeleteAccessPoint",
      # "elasticfilesystem:DeleteFileSystemPolicy",
      # "elasticfilesystem:DeleteReplicationConfiguration",
      # "elasticfilesystem:DescribeAccountPreferences",
      # "elasticfilesystem:DescribeBackupPolicy",
      # "elasticfilesystem:DescribeFileSystems",
      # "elasticfilesystem:DescribeFileSystemPolicy",
      # "elasticfilesystem:DescribeLifecycleConfiguration",
      # "elasticfilesystem:DescribeMountTargets",
      # "elasticfilesystem:DescribeMountTargetSecurityGroups",
      # "elasticfilesystem:DescribeTags",
      # "elasticfilesystem:DescribeAccessPoints",
      # "elasticfilesystem:DescribeReplicationConfigurations",
      # "elasticfilesystem:ModifyMountTargetSecurityGroups",
      # "elasticfilesystem:PutAccountPreferences",
      # "elasticfilesystem:PutBackupPolicy",
      # "elasticfilesystem:PutLifecycleConfiguration",
      # "elasticfilesystem:PutFileSystemPolicy",
      # "elasticfilesystem:UpdateFileSystem",
      # "elasticfilesystem:TagResource",
      # "elasticfilesystem:UntagResource",
      # "elasticfilesystem:ListTagsForResource",
      # "elasticfilesystem:Backup",
      # "elasticfilesystem:Restore",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cw_emitter" {
  name = "cloudwatchEmitter"

  policy = data.aws_iam_policy_document.cw_emitter.json
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

# # EFS definition to be used in the task definition

# resource "aws_efs_file_system" "mastofs" {
#   encrypted = true
# }

# resource "aws_efs_access_point" "masto_fs_ap" {
#   file_system_id = aws_efs_file_system.mastofs.id
# }

# resource "aws_efs_mount_target" "mast_fs_mt" {
#   for_each = {
#     key = "value"
#   }
#   file_system_id = aws_efs_file_system.mastofs.id
#   subnet_id      = var.private_subnet_id
# }

# Mastodon ECS service definition

resource "aws_ecs_service" "mastodon" {
  name                = "mastodon"
  cluster             = aws_ecs_cluster.mastodon.id
  task_definition     = aws_ecs_task_definition.mastodon_service.id
  desired_count       = 3
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

  #  Not allowed on Fargate!
  # ordered_placement_strategy {
  #   type  = "binpack"
  #   field = "cpu"
  # }

  # placement_constraints {
  #   type       = "memberOf"
  #   expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
  # }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# Mastodon ECS task to run in the Mastodon service

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "mastodon_service" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  task_role_arn            = aws_iam_role.mastodon_task.arn
  execution_role_arn       = aws_iam_role.fargate_runner.arn

  container_definitions = jsonencode([
    {
      name = "mastodon"
      # image       = "linuxserver/mastodon:4.1.0"
      image       = "nginxdemos/hello"
      networkMode = "awsvpc"
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

  # volume {
  #   name = "mastodon-storage"

  #   efs_volume_configuration {
  #     file_system_id          = aws_efs_file_system.mastofs.id
  #     root_directory          = "/data"
  #     transit_encryption      = "ENABLED"
  #     transit_encryption_port = 2999
  #     authorization_config {
  #       access_point_id = aws_efs_access_point.masto_fs_ap.id
  #       iam             = "ENABLED"
  #     }
  #   }

  #   # docker_volume_configuration {
  #   #   scope         = "shared"
  #   #   autoprovision = true
  #   #   driver        = "local"
  #   #   labels        = {}
  #   #   driver_opts = {
  #   #     "type"   = "nfs"
  #   #     "device" = "${aws_efs_file_system.fs.dns_name}:/"
  #   #     "o"      = "addr=${aws_efs_file_system.fs.dns_name},rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport"
  #   #   }
  #   # }
  # }

}
