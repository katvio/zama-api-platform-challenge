# Compute Infrastructure - Isolated State
# ECS Fargate, ALB, and compute-related components

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "zama-api-platform-terraform-state-1756826383"
    key            = "compute/terraform.tfstate"
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
      Component   = "compute"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "compute"
  }
}

# Data sources from other state files
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "networking/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "secrets" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "secrets/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "observability" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "observability/terraform.tfstate"
    region = var.aws_region
  }
}

# Compute Module (ECS Fargate)
module "compute" {
  source = "../../../modules/compute"
  
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix
  
  # Networking from remote state
  vpc_id                = data.terraform_remote_state.networking.outputs.vpc_id
  private_subnet_ids    = data.terraform_remote_state.networking.outputs.private_subnet_ids
  public_subnet_ids     = data.terraform_remote_state.networking.outputs.public_subnet_ids
  alb_security_group_id = data.terraform_remote_state.networking.outputs.alb_security_group_id
  alb_logs_bucket_name  = data.terraform_remote_state.networking.outputs.alb_logs_bucket_name
  
  # Docker images
  api_image_uri = var.api_image_uri
  
  # Secrets from remote state
  api_keys_secret_arn = data.terraform_remote_state.secrets.outputs.api_keys_secret_arn
  
  # Logging from remote state
  log_group_name = data.terraform_remote_state.observability.outputs.ecs_log_group_name
  
  # Configuration
  api_port = var.api_port
  
  # Resource allocation
  api_cpu    = var.api_cpu
  api_memory = var.api_memory
  
  # Scaling
  api_desired_count = var.api_desired_count
  api_min_capacity  = var.api_min_capacity
  api_max_capacity  = var.api_max_capacity
  
  # Health checks
  health_check_path                = var.health_check_path
  health_check_interval            = var.health_check_interval
  health_check_timeout             = var.health_check_timeout
  health_check_healthy_threshold   = var.health_check_healthy_threshold
  health_check_unhealthy_threshold = var.health_check_unhealthy_threshold
  
  tags = local.common_tags
}
