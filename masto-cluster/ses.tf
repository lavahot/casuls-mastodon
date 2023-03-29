# Create an email service for the ECS task to use

resource "aws_ses_domain_identity" "mastodon" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "mastodon" {
  domain = aws_ses_domain_identity.mastodon.domain
}

# resource "aws_route53_record" "mastodon_dkim" {
#   zone_id = var.zone_id
#   name    = "_amazonses.${var.domain_name}"
#   type    = "TXT"
#   ttl     = "600"
#   records = [aws_ses_domain_dkim.mastodon.dkim_tokens[0]]
# }

resource "aws_route53_record" "dkim_record" {
  zone_id = var.zone_id
  count   = 3
  name    = "${aws_ses_domain_dkim.mastodon.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  ttl     = "600"
  records = ["${aws_ses_domain_dkim.mastodon.dkim_tokens[count.index]}.dkim.amazonses.com"]
}

# resource "aws_ses_domain_identity_verification" "mastodon" {
#   domain = aws_ses_domain_identity.mastodon.id
#   depends_on = [
#     aws_route53_record.dkim_record,
#   ]
# }

# We're mailing from the domain, so this is unneccessary?
# resource "aws_ses_domain_mail_from" "mastodon" {
#   domain           = aws_ses_domain_identity.mastodon.id
#   mail_from_domain = var.domain_name
# }

# resource "aws_ses_identity_notification_topic" "mastodon" {
#   for_each          = toset(["Bounce", "Complaint", "Delivery"])
#   identity          = aws_ses_domain_identity.mastodon.id
#   notification_type = each.key
#   topic_arn         = aws_sns_topic.mastodon.arn
# }

# Create an SNS topic to receive SES notifications

# resource "aws_sns_topic" "mastodon" {
#   name = "mastodon"
# }

# resource "aws_sns_topic_policy" "mastodon" {
#   arn = aws_sns_topic.mastodon.arn

#   policy = data.aws_iam_policy_document.sns_policy.json
# }

# resource "aws_sns_topic_subscription" "mastodon" {
#   topic_arn = aws_sns_topic.mastodon.arn
#   protocol  = "email"
#   endpoint  = var.email

#   depends_on = [
#     aws_ses_domain_identity_verification.mastodon,
#   ]
# }

# data "aws_iam_policy_document" "sns_policy" {
#   statement {
#     effect = "Allow"
#     principals {
#       type        = "Service"
#       identifiers = ["ses.amazonaws.com"]
#     }
#     actions = ["SNS:Publish"]
#     resources = [
#       aws_sns_topic.mastodon.arn
#     ]
#     condition {
#       test     = "ArnEquals"
#       variable = "aws:SourceArn"
#       values = [
#         aws_ses_domain_identity.mastodon.arn
#       ]
#     }
#   }
# }

# resource "aws_iam_role_policy_attachment" "fr_ses_pa" {
#   role       = aws_iam_role.mastodon_task.name
#   policy_arn = aws_iam_policy.ses_emitter.arn
# }

# resource "aws_iam_role_policy_attachment" "fr_sns_pa" {
#   role       = aws_iam_role.mastodon_task.name
#   policy_arn = aws_iam_policy.sns_emitter.arn
# }

# Create a policy to allow the ECS task to send emails

data "aws_iam_policy_document" "ses_emitter" {
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "ses_emitter" {
  name = "sesEmitter"

  policy = data.aws_iam_policy_document.ses_emitter.json
}

# # Create a policy to allow the ECS task to send SNS notifications

# data "aws_iam_policy_document" "sns_emitter" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "sns:Publish",
#     ]
#     resources = [
#       aws_sns_topic.mastodon.arn,
#     ]
#   }
# }

# resource "aws_iam_policy" "sns_emitter" {
#   name   = "snsEmitter"
#   policy = data.aws_iam_policy_document.sns_emitter.json
# }

# create SMTP credentials for the ECS task to use

resource "aws_iam_access_key" "smtp" {
  user = aws_iam_user.smtp.name
}

resource "aws_iam_user" "smtp" {
  name = "smtp"
}

resource "aws_iam_user_policy_attachment" "smtp" {
  user       = aws_iam_user.smtp.name
  policy_arn = aws_iam_policy.ses_emitter.arn
}


# Create a secret to store the SMTP credentials

resource "aws_secretsmanager_secret" "smtp_user" {
  name                    = "MastodonSmtpUser"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "smtp_user" {
  secret_id     = aws_secretsmanager_secret.smtp_user.id
  secret_string = aws_iam_access_key.smtp.id
}

resource "aws_secretsmanager_secret" "smtp_password" {
  name                    = "MastodonSmtpPassword"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "smtp_password" {
  secret_id     = aws_secretsmanager_secret.smtp_password.id
  secret_string = aws_iam_access_key.smtp.ses_smtp_password_v4
}
