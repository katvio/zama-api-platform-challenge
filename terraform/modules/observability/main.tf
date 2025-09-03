# Observability Module for Zama API Platform Challenge
# Creates CloudWatch log groups, dashboards, and alarms

# CloudWatch Log Group for ECS Tasks
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/aws/ecs/${var.name_prefix}"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ecs-logs"
  })
}

# CloudWatch Log Group for Kong Gateway
resource "aws_cloudwatch_log_group" "kong" {
  name              = "/aws/ecs/${var.name_prefix}-kong"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kong-logs"
  })
}

# CloudWatch Log Group for API Service
resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/ecs/${var.name_prefix}-api"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-logs"
  })
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.name_prefix}-alb"],
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.name_prefix}-alb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_2XX_Count", "LoadBalancer", "${var.name_prefix}-alb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_4XX_Count", "LoadBalancer", "${var.name_prefix}-alb"],
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", "${var.name_prefix}-alb"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Application Load Balancer Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.name_prefix}-api-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name_prefix}-api-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.name_prefix}-kong-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "${var.name_prefix}-kong-service", "ClusterName", "${var.name_prefix}-cluster"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Service Resource Utilization"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${var.name_prefix}-api-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "PendingTaskCount", "ServiceName", "${var.name_prefix}-api-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${var.name_prefix}-kong-service", "ClusterName", "${var.name_prefix}-cluster"],
            ["AWS/ECS", "PendingTaskCount", "ServiceName", "${var.name_prefix}-kong-service", "ClusterName", "${var.name_prefix}-cluster"]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "ECS Task Counts"
          period  = 300
        }
      },
      {
        type   = "log"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          query   = "SOURCE '/aws/ecs/${var.name_prefix}-api' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          region  = var.aws_region
          title   = "Recent API Errors"
          view    = "table"
        }
      }
    ]
  })
}

# CloudWatch Alarms

# High Error Rate Alarm
resource "aws_cloudwatch_metric_alarm" "high_error_rate" {
  alarm_name          = "${var.name_prefix}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors 5XX errors from the load balancer"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "${var.name_prefix}-alb"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-high-error-rate-alarm"
  })
}

# High Response Time Alarm
resource "aws_cloudwatch_metric_alarm" "high_response_time" {
  alarm_name          = "${var.name_prefix}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "300"
  statistic           = "Average"
  threshold           = "2.0"
  alarm_description   = "This metric monitors response time from the load balancer"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = "${var.name_prefix}-alb"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-high-response-time-alarm"
  })
}

# ECS Service CPU High Utilization
resource "aws_cloudwatch_metric_alarm" "api_cpu_high" {
  alarm_name          = "${var.name_prefix}-api-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU utilization for the API service"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "${var.name_prefix}-api-service"
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-cpu-high-alarm"
  })
}

# ECS Service Memory High Utilization
resource "aws_cloudwatch_metric_alarm" "api_memory_high" {
  alarm_name          = "${var.name_prefix}-api-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors memory utilization for the API service"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "${var.name_prefix}-api-service"
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-memory-high-alarm"
  })
}

# Kong Gateway CPU High Utilization
resource "aws_cloudwatch_metric_alarm" "kong_cpu_high" {
  alarm_name          = "${var.name_prefix}-kong-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors CPU utilization for Kong Gateway"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ServiceName = "${var.name_prefix}-kong-service"
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-kong-cpu-high-alarm"
  })
}

# ECS Task Health Check Alarm
resource "aws_cloudwatch_metric_alarm" "unhealthy_tasks" {
  alarm_name          = "${var.name_prefix}-unhealthy-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the number of running tasks for the API service"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "breaching"

  dimensions = {
    ServiceName = "${var.name_prefix}-api-service"
    ClusterName = "${var.name_prefix}-cluster"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-unhealthy-tasks-alarm"
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.name_prefix}-alerts"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alerts-topic"
  })
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = "SNS:Publish"
        Resource = aws_sns_topic.alerts.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# Example SNS Subscription (Email)
# Uncomment and modify for actual use
# resource "aws_sns_topic_subscription" "email_alerts" {
#   topic_arn = aws_sns_topic.alerts.arn
#   protocol  = "email"
#   endpoint  = "your-email@example.com"
# }

# Custom Metric Filter for API Errors
resource "aws_cloudwatch_log_metric_filter" "api_errors" {
  name           = "${var.name_prefix}-api-errors"
  log_group_name = aws_cloudwatch_log_group.api.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "${var.name_prefix}-api-error-count"
    namespace = "ZamaAPI/Errors"
    value     = "1"
  }
}

# Custom Metric Filter for Kong Errors (keeping for future use)
resource "aws_cloudwatch_log_metric_filter" "kong_errors" {
  name           = "${var.name_prefix}-kong-errors"
  log_group_name = aws_cloudwatch_log_group.kong.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "${var.name_prefix}-kong-error-count"
    namespace = "ZamaAPI/Kong"
    value     = "1"
  }
}

# Custom Alarm for API Error Count
resource "aws_cloudwatch_metric_alarm" "api_error_count" {
  alarm_name          = "${var.name_prefix}-api-error-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "${var.name_prefix}-api-error-count"
  namespace           = "ZamaAPI/Errors"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors error count in API logs"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-error-count-alarm"
  })
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
