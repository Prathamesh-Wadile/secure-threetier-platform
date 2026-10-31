variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "A list of availability zones in the region"
}

variable "single_nat" {
  type        = bool
  description = "If true, provisions only 1 NAT Gateway to save costs. If false, provisions 1 per AZ."
}