terraform {
  required_version = ">= 1.10.0"
  backend "local" {}
}

provider "aws" {
  region = "us-east-1"
}

# The single source of truth for your remote state
resource "aws_s3_bucket" "terraform_state" {
  # MUST be globally unique. Change this name:
  bucket = "secure-threetier-tfstate-123456789"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}