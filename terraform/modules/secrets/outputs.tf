output "secret_arn" {
  description = "ARN of the Secrets Manager secret"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "kms_key_id" {
  description = "ID of the KMS key for secrets encryption"
  value       = aws_kms_key.secrets.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key for secrets encryption"
  value       = aws_kms_key.secrets.arn
}
