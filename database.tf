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
# lives entirely in private subnet
# encrypted at rest
# only EC2 can reach it via security group rule
# -----------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-mysql-db"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  enabled_cloudwatch_logs_exports = ["audit", "error", "general", "slowquery"]
  allocated_storage     = 20
  max_allocated_storage = 100
  iam_database_authentication_enabled = true
  auto_minor_version_upgrade = true
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn
  db_name  = "appdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  # critical security settings
  publicly_accessible = false
  storage_encrypted   = true
  multi_az            = true

  # backup
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  # dev settings — change these for prod
  skip_final_snapshot = true 
  deletion_protection = true
  tags = {
    Name = "${var.environment}-mysql-db"
  }
}
