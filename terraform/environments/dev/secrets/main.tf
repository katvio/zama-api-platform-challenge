# Secrets Management Infrastructure - Isolated State
# AWS Secrets Manager and related security components

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  backend "s3" {
    bucket         = "zama-api-platform-terraform-state-1756826383"
    key            = "secrets/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "zama-api-platform-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "secrets"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "secrets"
  }
}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Secrets Management
resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${local.name_prefix}-api-keys-${random_id.suffix.hex}"
  description             = "API keys for Kong Konnect authentication"
  recovery_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-api-keys"
  })
}

resource "aws_secretsmanager_secret_version" "api_keys" {
  secret_id = aws_secretsmanager_secret.api_keys.id
  secret_string = jsonencode({
    api_key_demo = var.demo_api_key
  })
}

# Additional secrets for different environments
resource "aws_secretsmanager_secret" "database_credentials" {
  name                    = "${local.name_prefix}-db-credentials-${random_id.suffix.hex}"
  description             = "Database credentials (placeholder for future use)"
  recovery_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-credentials"
  })
}

# Kong Konnect configuration secret (for storing Kong Konnect API tokens)
resource "aws_secretsmanager_secret" "kong_konnect_config" {
  name                    = "${local.name_prefix}-kong-konnect-${random_id.suffix.hex}"
  description             = "Kong Konnect API tokens and configuration"
  recovery_window_in_days = 7
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-kong-konnect"
  })
}

resource "aws_secretsmanager_secret_version" "kong_konnect_config" {
  secret_id = aws_secretsmanager_secret.kong_konnect_config.id
  secret_string = jsonencode({
    # These will be populated manually or via CI/CD
    kong_admin_token = "PLACEHOLDER_REPLACE_IN_CONSOLE"
    kong_api_url     = "PLACEHOLDER_REPLACE_IN_CONSOLE"
  })
}
