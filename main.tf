#------Define the AWS provider------
provider "aws" {
  region = "us-east-1"
}

#------Security Group allowing HTTP traffic------
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow HTTP traffic"

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

  tags = {
    Name = "web-sg"
  }
}

#------EC2 Instance with simple web server------
resource "aws_instance" "web_server" {
  ami                    = "ami-0c94855ba95c71c99"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd

              cat > /var/www/html/index.html <<'HTML'
              <!DOCTYPE html>
              <html>
              <head>
                <title>Welcome</title>
              </head>
              <body>
                <h1>Hello from Terraform!</h1>
                <p>This is a basic HTML page served by Apache HTTPd.</p>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "web-server"
  }
}
