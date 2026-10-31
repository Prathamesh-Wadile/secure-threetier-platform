output "vpc_id" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "List of IDs of public subnets"
}

output "private_app_subnet_ids" {
  value       = aws_subnet.private_app[*].id
  description = "List of IDs of private app subnets"
}

output "private_data_subnet_ids" {
  value       = aws_subnet.private_data[*].id
  description = "List of IDs of private data subnets"
}