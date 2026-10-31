variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "alb_arn" {
  type        = string
  description = "The ARN of the Application Load Balancer to attach the WAF to"
}