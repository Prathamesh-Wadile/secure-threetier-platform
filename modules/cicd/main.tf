/*
Inside the modules/cicd folder, create a file named main.tf and paste this code. This uses a dynamic 
data block to fetch GitHub's latest TLS fingerprint, creates the OIDC provider, and provisions an IAM 
role that only your specific repository can assume.
*/

# Dynamically fetch the GitHub OIDC TLS thumbprint
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

# Create the Identity Provider in AWS
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Create the IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "${var.environment}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = {
        StringLike = {
          # Strict boundary: Only your specific repository can assume this role
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo_name}:*"
        }
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# Attach AdministratorAccess so Terraform can provision resources in the CI/CD pipeline
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}