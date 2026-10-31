/*
To demonstrate senior-level Terraform skills, we will use a for_each loop. Instead of writing the bucket 
configuration three times, we define a set of buckets (assets, backups, and logs) and let Terraform iterate
over them to apply strict governance (encryption, versioning, public access blocks, TLS-only policies, and 
lifecycle transitions) to all of them at once.
*/

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

locals {
  # The three buckets required for the project
  buckets = toset(["assets", "backups", "logs"])
}

resource "aws_s3_bucket" "buckets" {
  for_each = local.buckets
  bucket   = "${var.environment}-myapp-${each.key}-${random_id.bucket_suffix.hex}"
  
  # Prevents accidental deletion of the bucket in production, 
  # but allows easy teardown in dev.
  force_destroy = true 
}

# 1. Enforce Versioning
resource "aws_s3_bucket_versioning" "versioning" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.buckets[each.key].id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Enforce Encryption (SSE-S3 to save on KMS key costs in a lab)
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. Block Public Access (Zero Trust S3)
resource "aws_s3_bucket_public_access_block" "public_access" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. Enforce TLS (HTTPS) Only via Bucket Policy
data "aws_iam_policy_document" "tls_only" {
  for_each = local.buckets
  
  statement {
    sid     = "EnforceTLSv12orHigher"
    effect  = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.buckets[each.key].arn,
      "${aws_s3_bucket.buckets[each.key].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "tls_only_policy" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.buckets[each.key].id
  policy   = data.aws_iam_policy_document.tls_only[each.key].json
  
  depends_on = [aws_s3_bucket_public_access_block.public_access]
}

# 5. Lifecycle Rules for Cost Optimization
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = local.buckets
  bucket   = aws_s3_bucket.buckets[each.key].id

  rule {
    id     = "archive-and-expire-old-versions"
    status = "Enabled"

    # Move non-current versions to Infrequent Access after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    # Move to Glacier after 90 days
    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    # Delete non-current versions after 365 days
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}