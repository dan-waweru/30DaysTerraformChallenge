#------Define the AWS provider------
provider "aws" {
  region = var.region
}

#------Create a security group for the web server------
resource "aws_security_group" "web_sg" {
  name        = var.aws_security_group  
  description = var.aws_security_group

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = var.cid_blocks
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cid_blocks
  }

}

#------EC2 Instance with simple web server------
/* resource "aws_instance" "web_server" {
 ami                    = var.ami
 instance_type          = var.instance_type
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
} */

#------Launch Configuration for Auto Scaling Group------
resource "aws_launch_configuration" "launch_configuration_example" {
  name          = "example-launch-configuration"
  image_id      = var.ami
  instance_type = var.instance_type
  security_groups = [aws_security_group.web_sg.id]
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
  
 /*To ensure that the launch configuration is recreated if the user data changes, we can use the lifecycle block with create_before_destroy set to true.
 This will allow Terraform to create a new launch configuration before destroying the old one, ensuring that there is no downtime for the Auto Scaling Group.*/
  lifecycle {
    create_before_destroy = true
  }
}
#------Auto Scaling Group------
resource "aws_autoscaling_group" "asg-example" {
  launch_configuration = aws_launch_configuration.launch_configuration_example.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  min_size = 2
  max_size = 10
  tag {
    key = "Name"
    value = "terraform_asg_example"
    propagate_at_launch = true
  }
}
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
#------Output the subnet IDs------
output "subnet_ids" {
  value = data.aws_subnets.default.ids
}