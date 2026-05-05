# -----------------------------------------------------------
# S3 bucket — application file storage
# accessed by EC2 via IAM role — zero hardcoded credentials
# -----------------------------------------------------------
resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }
}

resource "aws_s3_bucket_public_access_block" "app_bucket" {
  bucket                  = aws_s3_bucket.app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
resource "aws_sns_topic" "s3_notifications" {
  name              = "${var.environment}-s3-notifications"
  kms_master_key_id = aws_kms_key.cloudwatch_key.arn

  tags = {
    Name = "${var.environment}-s3-notifications"
  }
}

resource "aws_sns_topic_policy" "s3_notifications" {
  arn = aws_sns_topic.s3_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "s3.amazonaws.com" }
        Action    = "SNS:Publish"
        Resource  = aws_sns_topic.s3_notifications.arn
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.app_bucket.arn
          }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_notification" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.your_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.mykey.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.your_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.your_bucket.id

  topic {
    topic_arn     = aws_sns_topic.topic.arn
    events        = ["s3:ObjectCreated:*"]
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}
resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.my_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}
# Replication (Requires versioning and an IAM role)
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.my_bucket.id

  rules {
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}

# Notifications (Triggers EventBridge, SNS, or SQS)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.my_bucket.id
  eventbridge = true # Simplest way to satisfy the check
}
# Replication (Requires versioning and an IAM role)
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.my_bucket.id

  rules {
    status = "Enabled"
    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}

# Notifications (Triggers EventBridge, SNS, or SQS)
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket      = aws_s3_bucket.my_bucket.id
  eventbridge = true # Simplest way to satisfy the check
}
