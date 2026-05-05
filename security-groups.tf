# -----------------------------------------------------------
# EC2 security group — web server firewall
# -----------------------------------------------------------
resource "aws_security_group" "ec2" {
  name        = "${var.environment}-ec2-sg"
  description = "EC2 web server  HTTPS inbound only, all outbound"
  vpc_id      = aws_vpc.main.id

  # HTTPS only inbound — port 80 deliberately excluded
  # HTTP is unencrypted — all traffic must use HTTPS
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound allowed — EC2 needs to reach S3, RDS, internet
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-ec2-sg"
  }
}

# -----------------------------------------------------------
# RDS security group — database firewall
# only EC2 security group can reach it — nothing else
# -----------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.environment}-rds-sg"
  description = "RDS MySQL only EC2 security group allowed"
  vpc_id      = aws_vpc.main.id

  # MySQL port 3306 — only from EC2 security group
  # NOT from 0.0.0.0/0 — internet can never reach the database
  ingress {
    description     = "MySQL from EC2 only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment}-rds-sg"
  }
}
# EC2 security group egress — replace open egress with specific rules
egress {
  description = "HTTPS outbound to internet"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

egress {
  description = "HTTP outbound for package updates"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

egress {
  description = "MySQL outbound to RDS"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = [var.private_subnet_cidr]
}
# RDS security group egress — RDS doesnt need internet access
egress {
  description = "MySQL responses back to EC2 only"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = [var.public_subnet_cidr]
}
