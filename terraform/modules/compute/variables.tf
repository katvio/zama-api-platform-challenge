# Variables for Compute Module

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

# Networking
variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "IDs of the public subnets"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the ALB security group"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Name of the S3 bucket for ALB access logs"
  type        = string
}



# Docker Images
variable "api_image_uri" {
  description = "Docker image URI for the Go API service"
  type        = string
}

# Secrets
variable "api_keys_secret_arn" {
  description = "ARN of the API keys secret in Secrets Manager"
  type        = string
}

# Logging
variable "log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
}

# Configuration
variable "api_port" {
  description = "Port for the Go API service"
  type        = number
  default     = 8080
}

# Kong Konnect ports are managed externally

# Resource Allocation
variable "api_cpu" {
  description = "CPU units for API service (1024 = 1 vCPU)"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory in MB for API service"
  type        = number
  default     = 512
}

# Kong Konnect resources are managed externally

# Scaling Configuration
variable "api_desired_count" {
  description = "Desired number of API service tasks"
  type        = number
  default     = 2
}

variable "api_min_capacity" {
  description = "Minimum number of API service tasks"
  type        = number
  default     = 1
}

variable "api_max_capacity" {
  description = "Maximum number of API service tasks"
  type        = number
  default     = 10
}

# Kong Konnect scaling is managed externally

# Health Check Configuration
variable "health_check_path" {
  description = "Health check path for the API service"
  type        = string
  default     = "/healthz"
}

variable "health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 30
}

variable "health_check_timeout" {
  description = "Health check timeout in seconds"
  type        = number
  default     = 5
}

variable "health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks"
  type        = number
  default     = 2
}

variable "health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks"
  type        = number
  default     = 3
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
