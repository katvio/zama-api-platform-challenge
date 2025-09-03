# Outputs for Compute Infrastructure

# ECS Cluster
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.compute.ecs_cluster_name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.compute.ecs_cluster_arn
}

# ECS Service
output "api_service_name" {
  description = "Name of the API ECS service"
  value       = module.compute.api_service_name
}

output "api_service_arn" {
  description = "ARN of the API ECS service"
  value       = module.compute.api_service_arn
}

# Load Balancer
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = module.compute.alb_arn
}

# Service URLs
output "api_direct_url" {
  description = "Direct URL to the API service"
  value       = module.compute.api_direct_url
}

output "api_internal_url" {
  description = "Internal service discovery URL for the API"
  value       = module.compute.api_internal_url
}

# Service Discovery
output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = module.compute.service_discovery_namespace_name
}

# Testing Information
output "test_endpoints" {
  description = "Test endpoints for API validation"
  value = {
    direct_health_check = "curl -X GET ${module.compute.api_direct_url}/healthz"
    direct_sum_endpoint = "curl -X POST ${module.compute.api_direct_url}/api/v1/sum -H 'Content-Type: application/json' -d '{\"numbers\": [1, 2, 3, 4, 5]}'"
    kong_konnect_note   = "Configure Kong Konnect to proxy to: ${module.compute.api_direct_url}"
  }
}
