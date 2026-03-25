variable "server_port" {
  description = "The port the server should listen on"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ami" {
  description = "EC2 AMI ID"
  type        = string
  default     = "ami-0b0b78dcacbab728f"
}
variable "region" {
  default = "us-east-2"
}
variable "aws_security_group" {
  default     = "web-server-instance-sg"
  description = "Allow HTTP traffic"
  type        = string
}
variable "cid_blocks" {
  default = ["0.0.0.0/0"]

}
variable "alb_port" {
  default     = 80
  description = "The port the ALB should listen on"
  type        = number
}