# Create a random suffix for the s3 bucket names

resource "random_string" "s3_suffix" {
  length  = 8
  special = false
  lower   = true
  upper   = false
}

# Create an s3 bucket for the mastodon media files

resource "aws_s3_bucket" "mastodon_media" {
  bucket = "mastodon-media-${random_string.s3_suffix.result}"
  tags = {
    Name = "Mastodon media bucket"
  }
}

# Create an s3 acl for the mastodon media files

resource "aws_s3_bucket_public_access_block" "mastodon_media" {
  bucket                  = aws_s3_bucket.mastodon_media.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Create an s3 bucket policy document for the mastodon media files so that the ECS task can access them

data "aws_iam_policy_document" "s3_mastodon_media" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.fargate_runner.arn]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.mastodon_media.arn,
      "${aws_s3_bucket.mastodon_media.arn}/*",
    ]
  }
}

# Create an s3 bucket policy for the mastodon media files

resource "aws_s3_bucket_policy" "mastodon_media" {
  bucket = aws_s3_bucket.mastodon_media.id
  policy = data.aws_iam_policy_document.s3_mastodon_media.json
}

# Add an object lifecycle policy to the mastodon media bucket to transition files to glacier after 30 days

resource "aws_s3_bucket_lifecycle_configuration" "mastodon_media" {
  bucket = aws_s3_bucket.mastodon_media.id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }
  }
}
