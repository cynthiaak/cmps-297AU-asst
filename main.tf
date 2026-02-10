# -------------------------------
# Provider
# -------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
}

provider "aws" {
  region = var.aws_region
}

# -------------------------------
# Variables
# -------------------------------
variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "instance_name" {
  description = "EC2 instance name"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

# -------------------------------
# S3 Bucket
# -------------------------------
resource "aws_s3_bucket" "website_bucket" {
  bucket = var.bucket_name

  # AWS now enforces BucketOwnerEnforced by default, no ACLs allowed
  ownership_controls {
    rule {
      object_ownership = "BucketOwnerEnforced"
    }
  }
}

# S3 Bucket Website Configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Upload index.html to S3
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.id
  key          = "index.html"
  source       = "index.html"      # must match path in your GitHub repo
  content_type = "text/html"
}

# Public read bucket policy
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.website_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = "*"
        Action = "s3:GetObject"
        Resource = "${aws_s3_bucket.website_bucket.arn}/*"
      }
    ]
  })
}

# -------------------------------
# Security Group for EC2
# -------------------------------
resource "aws_security_group" "web_sg" {
  name        = "${var.instance_name}-sg"
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# -------------------------------
# EC2 Instance
# -------------------------------
resource "aws_instance" "web_server" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = "your-keypair-name" # replace with your AWS keypair
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform EC2 ${var.instance_name}!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = var.instance_name
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "ec2_public_ip" {
  description = "Public IP of EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "s3_website_url" {
  description = "S3 static website URL"
  value       = "http://${aws_s3_bucket.website_bucket.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}
