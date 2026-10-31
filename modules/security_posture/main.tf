/*
This file activates GuardDuty, sets up AWS Config with its required IAM role and S3 delivery bucket, 
and enables AWS Security Hub along with the CIS and AWS Foundational Security Best Practices frameworks.
*/

data "aws_region" "current" {}

# --- GUARDDUTY ---
resource "aws_guardduty_detector" "main" {
  enable = true
  tags   = { Name = "${var.environment}-guardduty" }
}

# --- SECURITY HUB ---
resource "aws_securityhub_account" "main" {}

resource "aws_securityhub_standards_subscription" "cis" {
  standards_arn = "arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"
  depends_on    = [aws_securityhub_account.main]
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  standards_arn = "arn:aws:securityhub:${data.aws_region.current.id}::standards/aws-foundational-security-best-practices/v/1.0.0"
  depends_on    = [aws_securityhub_account.main]
}

# --- AWS CONFIG ---
# 1. IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "${var.environment}-awsconfig-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "config.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# 2. S3 Bucket for AWS Config Logs
resource "random_id" "config_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "config_bucket" {
  bucket        = "${var.environment}-awsconfig-${random_id.config_suffix.hex}"
  force_destroy = true
}

# Allow AWS Config to read the ACL and write to the S3 bucket
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowConfigGetBucketAcl"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid       = "AllowConfigPutObject"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.config_bucket.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# 3. Configuration Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.environment}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# 4. Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.environment}-config-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

# 5. Enable the Recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}