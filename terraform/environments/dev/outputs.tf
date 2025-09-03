# Outputs for Zama API Platform Challenge

# Networking Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.networking.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

# Load Balancer Outputs
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = module.compute.alb_zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.alb_arn
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.compute.ecs_cluster_arn
}

output "api_service_name" {
  description = "Name of the API ECS service"
  value       = module.compute.api_service_name
}

# Kong Konnect service is managed externally

# Service Discovery Outputs
output "api_service_discovery_arn" {
  description = "ARN of the API service discovery service"
  value       = module.compute.api_service_discovery_arn
}

# Kong Konnect service discovery is managed externally

# Secrets Outputs
output "api_keys_secret_arn" {
  description = "ARN of the API keys secret in Secrets Manager"
  value       = aws_secretsmanager_secret.api_keys.arn
  sensitive   = true
}

# Monitoring Outputs
output "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = module.observability.ecs_log_group_name
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.observability.dashboard_name
}

# API Endpoints
output "api_direct_url" {
  description = "Direct URL to the API service (bypassing Kong Konnect)"
  value       = "http://${module.compute.alb_dns_name}:${var.api_port}"
}

# Health Check URLs
output "api_health_url" {
  description = "Direct API health check URL"
  value       = "http://${module.compute.alb_dns_name}:${var.api_port}/healthz"
}

# Kong Konnect health is managed externally

# Testing Information
output "test_endpoints" {
  description = "Test endpoints for API validation"
  value = {
    direct_health_check = "curl -X GET http://${module.compute.alb_dns_name}:${var.api_port}/healthz"
    direct_sum_endpoint = "curl -X POST http://${module.compute.alb_dns_name}:${var.api_port}/api/v1/sum -H 'Content-Type: application/json' -d '{\"numbers\": [1, 2, 3, 4, 5]}'"
    kong_konnect_note   = "Configure Kong Konnect to proxy to: http://${module.compute.alb_dns_name}:${var.api_port}"
  }
  sensitive = true
}

# Resource Information
output "resource_summary" {
  description = "Summary of created resources"
  value = {
    vpc_cidr             = var.vpc_cidr
    availability_zones   = length(data.aws_availability_zones.available.names)
    public_subnets       = length(var.public_subnet_cidrs)
    private_subnets      = length(var.private_subnet_cidrs)
    api_desired_count    = var.api_desired_count
    api_cpu_memory       = "${var.api_cpu}/${var.api_memory}"
    kong_konnect_note    = "Kong Gateway managed by Kong Konnect (serverless)"
  }
}
