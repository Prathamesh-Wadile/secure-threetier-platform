/*
Application Load Balancer (ALB), Auto Scaling Group (ASG), and the Security Group that bridges the internet 
to your database
*/

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the Application Load Balancer"
}

variable "private_app_subnet_ids" {
  type        = list(string)
  description = "List of private app subnet IDs for the Auto Scaling Group"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the application"
  default     = "t3.micro"
}