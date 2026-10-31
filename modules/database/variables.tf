variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the DB security group will be created"
}

variable "private_data_subnet_ids" {
  type        = list(string)
  description = "List of private data subnet IDs for the DB subnet group"
}

variable "app_security_group_id" {
  type        = string
  description = "The ID of the application security group allowed to access the database"
}

variable "db_instance_class" {
  type        = string
  description = "The RDS instance class"
  default     = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "Toggle for Multi-AZ deployment (false for dev, true for prod)"
  default     = false
}