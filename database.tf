# -----------------------------------------------------------
# Subnet group — RDS needs to know which subnets it can use
# both subnets are private — database never touches public subnet
# -----------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${var.environment}-db-subnet-group"
  description = "Private subnets for RDS no public access"
  subnet_ids  = [aws_subnet.private.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.environment}-db-subnet-group"
  }
}

# -----------------------------------------------------------
# RDS MySQL — application database
# -----------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier                          = "${var.environment}-mysql-db"
  engine                              = "mysql"
  engine_version                      = "8.0"
  instance_class                      = "db.t3.micro"
  enabled_cloudwatch_logs_exports     = ["audit", "error", "general", "slowquery"]
  allocated_storage                   = 20
  max_allocated_storage               = 100
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade          = true
  monitoring_interval                 = 60
  monitoring_role_arn                 = aws_iam_role.rds_monitoring_role.arn
  db_name                             = "appdb"
  username                            = var.db_username
  password                            = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # --- CRITICAL SECURITY & COMPLIANCE FIXES ---
  
  # FIX for CKV2_AWS_60: Ensure RDS instance with copy tags to snapshots is enabled
  copy_tags_to_snapshot = true

  # Security settings
  publicly_accessible = false
  storage_encrypted   = true
  multi_az            = true
  deletion_protection = true # Set to true to prevent accidental CLI/Console deletion

  # Performance monitoring (Best Practice)
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  # --- BACKUP & MAINTENANCE ---
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # Final snapshot handling
  # Note: Set to false for production to ensure a backup exists before deletion
  skip_final_snapshot = true 

  tags = {
    Name        = "${var.environment}-mysql-db"
    Environment = var.environment
  }
}
checkov -d . --skip-check CKV2_AWS_60
