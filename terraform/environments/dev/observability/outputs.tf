# Outputs for Observability Infrastructure

output "ecs_log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = module.observability.ecs_log_group_name
}

output "api_log_group_name" {
  description = "Name of the API CloudWatch log group"
  value       = module.observability.api_log_group_name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = module.observability.dashboard_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.observability.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.observability.sns_topic_arn
}

output "alarm_names" {
  description = "Names of all created CloudWatch alarms"
  value       = module.observability.alarm_names
}
