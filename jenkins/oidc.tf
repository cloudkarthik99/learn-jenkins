
# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]  # GitHub's OIDC thumbprint
  url             = "https://token.actions.githubusercontent.com"
}

# GitHub Actions IAM Role with OIDC Trust Policy
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_oidc.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
            # Replace with your GitHub organization and repository name
            "token.actions.githubusercontent.com:sub": "repo:cloudkarthik99/learn-jenkins:*"
          }
        }
      }
    ]
  })
}

# Policy for GitHub Actions to Provision Jenkins Infrastructure
resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-actions-provisioning-policy"
  description = "Policy to allow GitHub Actions to provision Jenkins infrastructure"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "*",
        Resource = "*"
      }
    ]
  })
}

# Attach GitHub Actions Policy to Role
resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}

