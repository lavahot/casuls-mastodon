# Generate a vapid public and private key pair for web push notifications with TLS

resource "tls_private_key" "mastodon_vapid" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

# Create a key to encrypt secrets with KMS

resource "aws_kms_key" "mastodon_secrets" {
  description = "Mastodon Secrets Key"
  tags = {
    Name = "MastodonSecretsKey"
  }
}

resource "aws_kms_alias" "mastodon_secrets" {
  name          = "alias/MastodonSecretsKey"
  target_key_id = aws_kms_key.mastodon_secrets.key_id
}

# Create a kms key policy to allow the ECS task to decrypt secrets

data "aws_iam_policy_document" "kms_decrypt" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.fargate_runner.arn]
    }
  }
}

resource "aws_kms_grant" "kms_decrypt" {
  key_id            = aws_kms_key.mastodon_secrets.key_id
  grantee_principal = aws_iam_role.fargate_runner.arn
  operations = [
    "Decrypt",
  ]
}

# Secret Manager secrets

locals {
  recovery_window_in_days = 0
}

# Vapid Keypair

resource "aws_secretsmanager_secret" "vapid_private_key" {
  name                    = "MastodonVapidPrivateKey"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonVapidPrivateKey"
  }
}

resource "aws_secretsmanager_secret_version" "vapid_private_key" {
  secret_id     = aws_secretsmanager_secret.vapid_private_key.id
  secret_string = replace(replace(base64encode(trimspace(tls_private_key.mastodon_vapid.private_key_openssh)), "+", "-"), "/", "_")
}

resource "aws_secretsmanager_secret" "vapid_public_key" {
  name                    = "MastodonVapidPublicKey"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonVapidPublicKey"
  }
}

resource "aws_secretsmanager_secret_version" "vapid_public_key" {
  secret_id     = aws_secretsmanager_secret.vapid_public_key.id
  secret_string = replace(replace(base64encode(trimspace(tls_private_key.mastodon_vapid.public_key_openssh)), "+", "-"), "/", "_")
}

# OTP Secret

resource "aws_secretsmanager_secret" "otp" {
  name                    = "MastodonOTP"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonOTP"
  }
}

resource "aws_secretsmanager_secret_version" "otp" {
  secret_id     = aws_secretsmanager_secret.otp.id
  secret_string = random_string.otp.result
}

resource "random_string" "otp" {
  length  = 128
  special = false
}

# Secret Key Base

resource "aws_secretsmanager_secret" "secret_key_base" {
  name                    = "MastodonSecretKeyBase"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonSecretKeyBase"
  }
}

resource "aws_secretsmanager_secret_version" "secret_key_base" {
  secret_id     = aws_secretsmanager_secret.secret_key_base.id
  secret_string = random_string.secret_key_base.result
}

resource "random_string" "secret_key_base" {
  length  = 128
  special = false
}

# DB Credentials
resource "aws_secretsmanager_secret" "db_user" {
  name                    = "MastodonDBUser"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonDBUser"
  }
}

resource "aws_secretsmanager_secret_version" "db_user" {
  secret_id     = aws_secretsmanager_secret.db_user.id
  secret_string = random_string.db_user.result
}

resource "random_string" "db_user" {
  length  = 32
  special = false
  upper   = false
  number  = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "MastodonDBPassword"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonDBPassword"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_string.db_password.result
}

resource "random_string" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# A secret for the admin username

resource "aws_secretsmanager_secret" "mastodon_admin_username" {
  name                    = "MastodonAdminUsername"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonAdminUsername"
  }
}

resource "aws_secretsmanager_secret_version" "mastodon_admin_username" {
  secret_id     = aws_secretsmanager_secret.mastodon_admin_username.id
  secret_string = var.admin_user_name
}

# A secret for the admin email

resource "aws_secretsmanager_secret" "mastodon_admin_email" {
  name                    = "MastodonAdminEmail"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonAdminEmail"
  }
}

resource "aws_secretsmanager_secret_version" "mastodon_admin_email" {
  secret_id     = aws_secretsmanager_secret.mastodon_admin_email.id
  secret_string = var.admin_email_address
}

# A secret for the admin password

resource "aws_secretsmanager_secret" "mastodon_admin_password" {
  name                    = "MastodonAdminPassword"
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
  recovery_window_in_days = local.recovery_window_in_days
  tags = {
    Name = "MastodonAdminPassword"
  }
}

resource "aws_secretsmanager_secret_version" "mastodon_admin_password" {
  secret_id     = aws_secretsmanager_secret.mastodon_admin_password.id
  secret_string = var.admin_initial_password
}
