variable "server_port" {
  description = "The port the server should listen on"
  type        = number
  default     = 8080    
}
output "public_ip" {
  value = aws_instance.web_server.public_ip
  description = "Our web server public IP address:"
}