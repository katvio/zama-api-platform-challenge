# Observability Infrastructure - Isolated State
# CloudWatch, Monitoring, Alerting, and Logging components

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
    key            = "observability/terraform.tfstate"
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
      Component   = "observability"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "observability"
  }
}

# Data sources
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "networking/terraform.tfstate"
    region = var.aws_region
  }
}

# Data source for compute state to get ALB DNS name
data "terraform_remote_state" "compute" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "compute/terraform.tfstate"
    region = var.aws_region
  }
}

# Observability Module
module "observability" {
  source = "../../../modules/observability"
  
  project_name = var.project_name
  environment  = var.environment
  name_prefix  = local.name_prefix
  aws_region   = var.aws_region
  
  # VPC info from networking state
  vpc_id = data.terraform_remote_state.networking.outputs.vpc_id
  
  # Enhanced monitoring configuration
  alert_email   = var.alert_email
  alb_dns_name  = try(data.terraform_remote_state.compute.outputs.alb_dns_name, "")
  api_port      = var.api_port
  
  log_retention_days = var.log_retention_days
  
  tags = local.common_tags
}
