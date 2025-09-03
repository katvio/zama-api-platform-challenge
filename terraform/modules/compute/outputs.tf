# Outputs for Compute Module

# ECS Cluster
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

# ECS Services
output "api_service_name" {
  description = "Name of the API ECS service"
  value       = aws_ecs_service.api.name
}

output "api_service_arn" {
  description = "ARN of the API ECS service"
  value       = aws_ecs_service.api.id
}

# Kong Konnect service is managed externally

# Task Definitions
output "api_task_definition_arn" {
  description = "ARN of the API task definition"
  value       = aws_ecs_task_definition.api.arn
}

# Kong Konnect task definition is managed externally

# Service Discovery
output "api_service_discovery_arn" {
  description = "ARN of the API service discovery service"
  value       = aws_service_discovery_service.api.arn
}

# Kong Konnect service discovery is managed externally

output "service_discovery_namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "service_discovery_namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

# Load Balancer Components
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

# Target Groups
output "api_target_group_arn" {
  description = "ARN of the API target group"
  value       = aws_lb_target_group.api.arn
}

# Kong Konnect target groups are managed externally

# Listeners
output "api_listener_arn" {
  description = "ARN of the API listener"
  value       = aws_lb_listener.api.arn
}

# Kong Konnect listeners are managed externally

# Auto Scaling
output "api_autoscaling_target_arn" {
  description = "ARN of the API auto scaling target"
  value       = aws_appautoscaling_target.api.arn
}

# Kong Konnect auto scaling is managed externally

# Kong Konnect doesn't need EFS - configuration is managed externally

# IAM Roles
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task_role.arn
}

# Service URLs
output "api_direct_url" {
  description = "Direct URL to the API service"
  value       = "http://${aws_lb.main.dns_name}:${var.api_port}"
}

# Kong Konnect URLs are managed externally and provided by Kong Konnect dashboard

# Internal Service Discovery URLs
output "api_internal_url" {
  description = "Internal service discovery URL for the API"
  value       = "http://api.${aws_service_discovery_private_dns_namespace.main.name}:${var.api_port}"
}

# Kong Konnect internal URLs are managed externally
