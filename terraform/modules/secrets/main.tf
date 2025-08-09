# Secrets Manager for sensitive configuration
resource "aws_secretsmanager_secret" "app_secrets" {
  name        = var.secret_name
  description = "Application secrets for React app"
  
  # Enable automatic rotation if needed
  # rotation_lambda_arn = aws_lambda_function.rotation.arn
  # rotation_rules {
  #   automatically_after_days = 30
  # }
  
  tags = var.common_tags
}

resource "aws_secretsmanager_secret_version" "app_secrets" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    database_password = var.database_password
    api_key          = var.api_key
    jwt_secret       = var.jwt_secret
  })
}

# SSM Parameters for non-sensitive config
resource "aws_ssm_parameter" "app_config" {
  for_each = var.app_parameters
  
  name  = "/react-app/${var.environment}/${each.key}"
  type  = "String"
  value = each.value
  
  tags = var.common_tags
}

# KMS key for secrets encryption
resource "aws_kms_key" "secrets" {
  description             = "KMS key for secrets encryption"
  deletion_window_in_days = 7
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
  
  tags = var.common_tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/react-app-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_caller_identity" "current" {}
