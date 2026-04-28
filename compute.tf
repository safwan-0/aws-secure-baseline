# -----------------------------------------------------------
# Find latest Amazon Linux 2023 AMI automatically
# data block reads from AWS — does not create anything
# -----------------------------------------------------------
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# -----------------------------------------------------------
# EC2 instance — web server
# lives in public subnet
# no SSH open — use AWS Systems Manager for access
# IAM role attached — accesses S3 without any keys
# -----------------------------------------------------------
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  # IMDSv2 enforcement — prevents SSRF attacks stealing credentials
  # without this an attacker can query the metadata service
  # and steal your IAM role credentials
  metadata_options {
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    http_endpoint               = "enabled"
  }

  # root volume encrypted
  root_block_device {
    volume_size           = 30
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "${var.environment}-web-server"
  }
}
