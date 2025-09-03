# Outputs for Observability Module

output "ecs_log_group_name" {
  description = "Name of the ECS CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "ecs_log_group_arn" {
  description = "ARN of the ECS CloudWatch log group"
  value       = aws_cloudwatch_log_group.ecs.arn
}

output "kong_log_group_name" {
  description = "Name of the Kong CloudWatch log group"
  value       = aws_cloudwatch_log_group.kong.name
}

output "kong_log_group_arn" {
  description = "ARN of the Kong CloudWatch log group"
  value       = aws_cloudwatch_log_group.kong.arn
}

output "api_log_group_name" {
  description = "Name of the API CloudWatch log group"
  value       = aws_cloudwatch_log_group.api.name
}

output "api_log_group_arn" {
  description = "ARN of the API CloudWatch log group"
  value       = aws_cloudwatch_log_group.api.arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.name
}

output "alarm_names" {
  description = "Names of all created CloudWatch alarms"
  value = concat([
    aws_cloudwatch_metric_alarm.high_error_rate.alarm_name,
    aws_cloudwatch_metric_alarm.high_response_time.alarm_name,
    aws_cloudwatch_metric_alarm.api_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.api_memory_high.alarm_name,
    aws_cloudwatch_metric_alarm.kong_cpu_high.alarm_name,
    aws_cloudwatch_metric_alarm.unhealthy_tasks.alarm_name,
    aws_cloudwatch_metric_alarm.api_error_count.alarm_name
  ],
  var.alb_dns_name != "" ? [
    aws_cloudwatch_metric_alarm.alb_unhealthy_targets[0].alarm_name,
    aws_cloudwatch_metric_alarm.no_healthy_targets[0].alarm_name,
    aws_cloudwatch_metric_alarm.low_request_count[0].alarm_name,
    aws_cloudwatch_metric_alarm.health_endpoint_slow_response[0].alarm_name,
    aws_cloudwatch_metric_alarm.alb_connection_errors[0].alarm_name
  ] : []
  )
}

output "metric_filter_names" {
  description = "Names of all created metric filters"
  value = [
    aws_cloudwatch_log_metric_filter.api_errors.name,
    aws_cloudwatch_log_metric_filter.kong_errors.name
  ]
}
