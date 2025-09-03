# Outputs for Secrets Management

output "api_keys_secret_arn" {
  description = "ARN of the API keys secret in Secrets Manager"
  value       = aws_secretsmanager_secret.api_keys.arn
  sensitive   = true
}

output "api_keys_secret_name" {
  description = "Name of the API keys secret in Secrets Manager"
  value       = aws_secretsmanager_secret.api_keys.name
  sensitive   = true
}

output "database_credentials_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database_credentials.arn
  sensitive   = true
}

output "kong_konnect_config_secret_arn" {
  description = "ARN of the Kong Konnect configuration secret"
  value       = aws_secretsmanager_secret.kong_konnect_config.arn
  sensitive   = true
}

output "kong_konnect_config_secret_name" {
  description = "Name of the Kong Konnect configuration secret"
  value       = aws_secretsmanager_secret.kong_konnect_config.name
  sensitive   = true
}
