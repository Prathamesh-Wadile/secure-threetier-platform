/*
This file exports the application security group ID (which the database module needs to allow traffic) 
and the public DNS name of your load balancer (so you can test the website in your browser).
*/

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "The ID of the application security group"
}

output "alb_dns_name" {
  value       = aws_lb.app.dns_name
  description = "The DNS name of the Application Load Balancer"
}

output "alb_arn" {
  value       = aws_lb.app.arn
  description = "The ARN of the Application Load Balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.app.name
  description = "The name of the Auto Scaling Group"
}

output "alb_arn_suffix" {
  value       = aws_lb.app.arn_suffix
  description = "The ARN suffix of the Application Load Balancer (used for CloudWatch metrics)"
}