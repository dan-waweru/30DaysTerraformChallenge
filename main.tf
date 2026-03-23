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
  ami                    = "ami-0c94855ba95c71c99"
 instance_type          = "t2.micro"
 vpc_security_group_ids = [aws_security_group.web_sg.id]  
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  user_data_replace_on_change = true

  tags = {
    Name = "web-server"
  }
}
