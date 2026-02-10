# -------------------------------
# Provider
# -------------------------------
provider "aws" {
  region = "eu-north-1"
}

# -------------------------------
# S3 Bucket for Static Website
# -------------------------------
resource "aws_s3_bucket" "website_bucket" {
  bucket = "aub-lab4-cynthia-khalil"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "error.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "index.html"
  source       = "index.html"      # upload your local index.html file in Terraform Cloud
  content_type = "text/html"
}

# -------------------------------
# Security Group for EC2
# -------------------------------
resource "aws_security_group" "web_sg" {
  name        = "aub-lab4-sg"
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
  ami           = "ami-0e530657722215a4d"  # update if needed
  instance_type = "t2.micro"
  key_name      = "your-keypair-name"      # replace with your AWS keypair
  security_groups = [aws_security_group.web_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from Terraform EC2 aub-lab4!</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name = "aub-lab4"
  }
}

# -------------------------------
# Outputs
# -------------------------------
output "ec2_public_ip" {
  value = aws_instance.web_server.public_ip
}

output "s3_website_url" {
  value = aws_s3_bucket.website_bucket.website_endpoint
}
