# Main Terraform configuration for Zama API Platform Challenge
# This configuration deploys a Go API service to AWS ECS Fargate with Kong Gateway

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = "zama-devops-challenge"
  }
}

# Data sources for existing resources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

# Random suffix for unique resource naming
resource "random_id" "suffix" {
  byte_length = 4
}

# Networking Module
module "networking" {
  source = "../../modules/networking"
  
  project_name        = var.project_name
  environment         = var.environment
  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  availability_zones  = data.aws_availability_zones.available.names
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  
  tags = local.common_tags
}

# Observability Module
module "observability" {
  source = "../../modules/observability"
  
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix
  
  # VPC and networking info for VPC Flow Logs
  vpc_id = module.networking.vpc_id
  
  tags = local.common_tags
}

# Secrets Management
resource "aws_secretsmanager_secret" "api_keys" {
  name                    = "${local.name_prefix}-api-keys-${random_id.suffix.hex}"
  description             = "API keys for Kong Gateway authentication"
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

# Compute Module (ECS Fargate)
module "compute" {
  source = "../../modules/compute"
  
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix
  
  # Networking
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  alb_logs_bucket_name = module.networking.alb_logs_bucket_name
  
  # Docker images
  api_image_uri  = var.api_image_uri
  
  # Secrets
  api_keys_secret_arn = aws_secretsmanager_secret.api_keys.arn
  
  # Logging
  log_group_name = module.observability.ecs_log_group_name
  
  # Configuration
  api_port      = var.api_port
  
  tags = local.common_tags
}
