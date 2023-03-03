# Generate a vapid public and private key pair with KMS

# resource "aws_kms_key" "mastodon_vapid" {
#   description = "Mastodon Vapid Key"
#   tags = {
#     Name = "MastodonVapidKey"
#   }
# }

# resource "aws_kms_alias" "mastodon_vapid" {
#   name          = "alias/MastodonVapidKey"
#   target_key_id = aws_kms_key.mastodon_vapid.key_id
# }

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


# Secret Manager secrets

# Vapid Keypair

resource "aws_secretsmanager_secret" "vapid_private_key" {
  name       = "MastodonVapidPrivateKey"
  kms_key_id = aws_kms_key.mastodon_secrets.arn
  tags = {
    Name = "MastodonVapidPrivateKey"
  }
}

resource "aws_secretsmanager_secret_version" "vapid_private_key" {
  secret_id     = aws_secretsmanager_secret.vapid_private_key.id
  secret_string = tls_private_key.mastodon_vapid.private_key_pem
}

resource "aws_secretsmanager_secret" "vapid_public_key" {
  name       = "MastodonVapidPublicKey"
  kms_key_id = aws_kms_key.mastodon_secrets.arn
  tags = {
    Name = "MastodonVapidPublicKey"
  }
}

resource "aws_secretsmanager_secret_version" "vapid_public_key" {
  secret_id     = aws_secretsmanager_secret.vapid_public_key.id
  secret_string = tls_private_key.mastodon_vapid.public_key_pem
}

# OTP Secret

resource "aws_secretsmanager_secret" "otp" {
  name                    = "MastodonOTP"
  recovery_window_in_days = 30
  kms_key_id              = aws_kms_key.mastodon_secrets.arn
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
  name       = "MastodonSecretKeyBase"
  kms_key_id = aws_kms_key.mastodon_secrets.arn
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
esource "aws_secretsmanager_secret" "db_user" {
  name       = "MastodonDBUser"
  kms_key_id = aws_kms_key.mastodon_secrets.arn
  tags = {
    Name = "MastodonDBUser"
  }
}

resource "aws_secretsmanager_secret_version" "db_user" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_string.db_password.result
}

resource "random_string" "db_user" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "MastodonDBPassword"
  kms_key_id = aws_kms_key.mastodon_secrets.arn
  tags = {
    Name = "MastodonDBPassword"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_string.db_password.result
}

resource "random_string" "db_password" {
  length  = 32
  special = false
}
