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
      "secretsmanager:GetSecretValue",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_task_decrypt_secrets" {
  statement {
    actions = [
      "kms:Decrypt",
    ]
    resources = [aws_kms_key.mastodon_secrets.arn]
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


# CW Log stream for ECS cluster
resource "aws_cloudwatch_log_stream" "masto_cluster_stream" {
  name           = "masto_cluster_stream"
  log_group_name = aws_cloudwatch_log_group.mastodon_cw_group.name
}

resource "aws_ecs_cluster" "mastodon" {
  name = "mastodon"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = false
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.mastodon_cw_group.name
      }
    }
  }
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
