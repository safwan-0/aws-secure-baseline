# -----------------------------------------------------------
# EC2 role — lets server access S3 without any hardcoded keys
# -----------------------------------------------------------
resource "aws_iam_role" "ec2_role" {
  name        = "${var.environment}-ec2-role"
  description = "Allows EC2 to access S3 no hardcoded credentials"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-ec2-role"
  }
}

# -----------------------------------------------------------
# S3 access policy — least privilege
# only the actions the web server actually needs
# -----------------------------------------------------------
resource "aws_iam_policy" "ec2_s3_policy" {
  name        = "${var.environment}-ec2-s3-policy"
  description = "EC2 read/write access to app S3 bucket only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        # locked to this specific bucket only
        # not s3:* and not all buckets
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      }
    ]
  })
}

# -----------------------------------------------------------
# Attach policy to role
# -----------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ec2_s3" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

# -----------------------------------------------------------
# Instance profile — required wrapper for EC2 to use a role
# -----------------------------------------------------------
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.environment}-ec2-profile"
  }
}

# -----------------------------------------------------------
# CloudTrail role — allows CloudTrail to write logs
# -----------------------------------------------------------
resource "aws_iam_role" "cloudtrail_role" {
  name = "${var.environment}-cloudtrail-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.environment}-cloudtrail-role"
  }
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "${var.environment}-cloudtrail-policy"
  role = aws_iam_role.cloudtrail_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
