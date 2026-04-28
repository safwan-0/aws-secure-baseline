output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ec2_instance_id" {
  description = "EC2 web server instance ID"
  value       = aws_instance.web.id
}

output "ec2_private_ip" {
  description = "EC2 private IP address"
  value       = aws_instance.web.private_ip
}

output "rds_endpoint" {
  description = "RDS connection endpoint — internal only, not reachable from internet"
  value       = aws_db_instance.main.endpoint
}

output "rds_port" {
  description = "RDS port"
  value       = aws_db_instance.main.port
}

output "s3_bucket_name" {
  description = "Application S3 bucket name"
  value       = aws_s3_bucket.app_bucket.id
}

output "s3_bucket_arn" {
  description = "Application S3 bucket ARN"
  value       = aws_s3_bucket.app_bucket.arn
}

output "ec2_iam_role_arn" {
  description = "EC2 IAM role ARN"
  value       = aws_iam_role.ec2_role.arn
}
