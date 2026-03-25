#------Define the AWS provider------
provider "aws" {
  region = var.region
}

#------Create a security group for the web server------
resource "aws_security_group" "web_sg" {
  name        = var.aws_security_group
  description = "Allow HTTP traffic"

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
resource "aws_launch_template" "template_example" {
  name_prefix            = "example-launch-configuration"
  image_id               = var.ami
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  user_data = base64encode(<<-EOF
  #!/bin/bash
  yum update -y
  yum install -y httpd

  #Change Apache to listen on port 8080
  sed -i 's/^Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

  systemctl start httpd
  systemctl enable httpd
  echo "<h1>Welcome to my Terraform-deployed server 🚀</h1>" > /var/www/html/index.html
  EOF
  )

  /*To ensure that the launch configuration is recreated if the user data changes, we can use the lifecycle block with create_before_destroy set to true.
 This will allow Terraform to create a new launch configuration before destroying the old one, ensuring that there is no downtime for the Auto Scaling Group.*/
  lifecycle {
    create_before_destroy = true
  }
}

#------Auto Scaling Group------
resource "aws_autoscaling_group" "asg-example" {
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg_target_group.arn]
  health_check_type   = "ELB"
  launch_template {
    id      = aws_launch_template.template_example.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 10
  tag {
    key                 = "Name"
    value               = "terraform_asg_example"
    propagate_at_launch = true
  }
}

#----lookup the default VPC and its subnets------
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


######------Create an Application Load Balancer and related resources------
#-------Create an Application Load Balancer------
resource "aws_lb" "alb_example" {
  name               = "app-lb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = "app-lb"
  }
}
#----Defining a listener for the ALB------
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb_example.arn
  port              = 80
  protocol          = "HTTP"

  #--By default,return a simple 404 page-----
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found"
      status_code  = "404"
    }
  }
}
#-----Security group for ALB to allow inbound traffic on port 80-----
resource "aws_security_group" "alb_sg" {
  name        = "alb_security_group"
  description = "Allow inbound traffic on port 80 for ALB"

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
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
#------Target Group for the security group------
# The target group will be associated with the Auto Scaling Group to route traffic to the EC2 instances.
# The health check configuration ensures that the ALB only routes traffic to healthy instances.
resource "aws_lb_target_group" "asg_target_group" {
  name     = "target-group"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

#--Listener rule to forward traffic from the ALB to the target group------
resource "aws_lb_listener_rule" "forward_to_asg" {
  listener_arn = aws_lb_listener.alb_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

##----Outputs to display the ALB DNS name and the Auto Scaling Group name after deployment------
output "alb_dns_name" {
  value       = aws_lb.alb_example.dns_name
  description = "The DNS name of the Load Balancer"
}