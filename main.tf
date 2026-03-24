#------Define the AWS provider------
provider "aws" {
  region = "us-east-1"
}

#------Create a security group for the web server------
resource "aws_security_group" "web_sg" {
  name        = "web-server-instance-sg"
  description = "Allow HTTP traffic"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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

#------EC2 Instance with simple web server------
resource "aws_instance" "web_server" {
ami                    = "ami-02dfbd4ff395f2a1b"
 instance_type          = "t3.micro"
vpc_security_group_ids = [aws_security_group.web_sg.id]  
user_data = <<-EOF
 #!/bin/bash
yum update -y
yum install -y httpd

#Change Apache to listen on port 8080
sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

systemctl start httpd
systemctl enable httpd

echo "<h1>Welcome to my Terraform-deployed server 🚀</h1>" > /var/www/html/index.html
EOF
user_data_replace_on_change = true

  tags = {
    Name = "web-server"
  }
}
