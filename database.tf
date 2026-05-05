# -----------------------------------------------------------
# Subnet group — RDS needs to know which subnets it can use
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
  
  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  
  # Credentials
  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  # Network
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # --- SECURITY & COMPLIANCE FIXES ---
  
  # FIX for CKV2_AWS_60: copy tags to snapshots
  copy_tags_to_snapshot = true

  # Encryption & Access
  publicly_accessible = false
  storage_encrypted   = true
  # Best practice: link to a specific KMS key if required by your org
  # kms_key_id        = aws_kms_key.database_key.arn 

  # Availability
  multi_az            = true
  deletion_protection = true

  # Performance
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  # FIX: performance insights usually require a KMS key to be fully compliant
  performance_insights_kms_key_id       = aws_kms_key.my_key.arn

  # --- BACKUP & MAINTENANCE ---
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00" # Use lowercase for 'mon' to avoid provider quirks

  # Final snapshot handling
  skip_final_snapshot = false # Changed to false for production safety
  final_snapshot_identifier = "${var.environment}-mysql-db-final-snapshot"

  tags = {
    Name        = "${var.environment}-mysql-db"
    Environment = var.environment
  }
}
