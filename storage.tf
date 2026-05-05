# 1. The Main S3 Bucket
resource "aws_s3_bucket" "app_bucket" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name = var.bucket_name
  }
}

# 2. Block Public Access (Security Best Practice)
resource "aws_s3_bucket_public_access_block" "app_bucket" {
  bucket                  = aws_s3_bucket.app_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Enable Versioning (Required for Replication)
resource "aws_s3_bucket_versioning" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 4. FIX CKV_AWS_145: Encrypt with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      # Ensure aws_kms_key.my_key is defined in your variables/kms.tf
      kms_master_key_id = aws_kms_key.my_key.arn 
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# 5. FIX CKV_AWS_18: Enable Access Logging
# Note: You must have a separate 'log_bucket' defined elsewhere
resource "aws_s3_bucket_logging" "app_bucket" {
  bucket = aws_s3_bucket.app_bucket.id

  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/app_bucket/"
}

# 6. FIX CKV_AWS_144: Cross-Region Replication
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Ensure aws_iam_role.replication and aws_s3_bucket.destination are defined
  depends_on = [aws_s3_bucket_versioning.app_bucket]
  role       = aws_iam_role.replication.arn
  bucket     = aws_s3_bucket.app_bucket.id

  rules {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}

# 7. Lifecycle Configuration
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

# 8. Notifications (SNS and EventBridge)
resource "aws_s3_bucket_notification" "app_bucket" {
  bucket      = aws_s3_bucket.app_bucket.id
  eventbridge = true 

  topic {
    topic_arn = aws_sns_topic.s3_notifications.arn
    events    = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
  }
}
