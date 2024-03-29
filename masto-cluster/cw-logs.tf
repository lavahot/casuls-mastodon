# Create IAM policy for cw logs attached to ecsInstanceRole? Only when using
# user created roles. The service-linked role does this for FARGATE.

# Create CW log group
resource "aws_cloudwatch_log_group" "mastodon_cw_group" {
  name = "mastodon_cw_group"
}

# Create CW log stream with mastodon prefix

resource "random_string" "masto_stream_suffix" {
  length  = 8
  special = false
}

resource "aws_cloudwatch_log_stream" "mastodon" {
  name           = format("%s-%s", local.cluster_name, random_string.masto_stream_suffix.result)
  log_group_name = aws_cloudwatch_log_group.mastodon_cw_group.name
}


# Create CW log group for fargate runner
resource "aws_cloudwatch_log_group" "fargate_runner_cw_group" {
  name = "fargate_runner_cw_group"
}

# Add cloud logging permissions

data "aws_iam_policy_document" "cw_emitter" {
  statement {
    actions = [
      # TODO: split ECR and CW permissions
      "ecr:GetAuthorizationToken",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      # TODO: restrict to specific log group

      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "cw_emitter" {
  name = "cloudwatchEmitter"

  policy = data.aws_iam_policy_document.cw_emitter.json
}
