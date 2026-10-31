output "website_url" {
  value       = "http://${module.compute.alb_dns_name}"
  description = "The public URL to access the application"
}

output "database_endpoint" {
  value       = module.database.db_endpoint
  description = "The internal RDS endpoint"
}

output "github_actions_role_arn" {
  value       = module.cicd.github_actions_role_arn
  description = "Copy this ARN to your GitHub Actions workflow"
}