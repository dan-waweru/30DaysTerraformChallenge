#------Define the AWS provider------
provider "aws" {
  region = "us-east-1"
}

#------Create a security group for the web server------
resource "aws_security_group" "web_sg" {
  name        = "web-server-instance-sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------EC2 Instance with simple web server------
resource "aws_instance" "web_server" {
ami                    = "ami-02dfbd4ff395f2a1b"
 instance_type          = "t3.micro"
 vpc_security_group_ids = [aws_security_group.web_sg.id]  
user_data = <<-EOF
 #!/bin/bash
yum update -y
yum install -y httpd

systemctl start httpd
systemctl enable httpd

echo "<h1>Welcome to my Terraform-deployed server 🚀</h1>" > /var/www/html/index.html
EOF
user_data_replace_on_change = true

  tags = {
    Name = "web-server"
  }
}
