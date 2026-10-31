variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, prod)"
}

variable "sns_alert_email" {
  type        = string
  description = "The email address that will receive critical infrastructure alerts"
}

variable "asg_name" {
  type        = string
  description = "The name of the Auto Scaling Group to monitor"
}

variable "alb_arn_suffix" {
  type        = string
  description = "The ARN suffix of the Application Load Balancer for HTTP metrics"
}