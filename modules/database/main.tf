/*
This code does a few critical things for a production-grade setup: it creates a dedicated security group 
that only accepts traffic from your future app instances, dynamically generates a secure password, stores 
it safely in AWS Secrets Manager, and provisions the RDS database.
*/

# The subnet group places the database in your isolated data subnets
resource "aws_db_subnet_group" "main" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids
  tags       = { Name = "${var.environment}-db-subnet-group" }
}

# The security group ensures only the application layer can talk to the database
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allow inbound traffic from the application layer"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL access from App SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.app_security_group_id]
  }

  tags = { Name = "${var.environment}-db-sg" }
}

# Generate a secure password dynamically (no hardcoded secrets)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store the credentials securely in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "${var.environment}-rds-postgres-credentials"
  recovery_window_in_days = 0 # Forces immediate deletion for lab environments
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

# The actual RDS instance
resource "aws_db_instance" "postgres" {
  identifier             = "${var.environment}-postgres"
  engine                 = "postgres"
  engine_version         = "16.3" 
  instance_class         = var.db_instance_class
  allocated_storage      = 20
  
  db_name                = "appdb"
  username               = "dbadmin"
  password               = random_password.db_password.result
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  multi_az               = var.multi_az
  
  storage_encrypted      = true
  
  # Crucial for a lab environment to allow fast teardowns with 'terraform destroy'
  skip_final_snapshot    = true 
  apply_immediately      = true
}