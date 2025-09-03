# Variables for Compute Infrastructure

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-west-1"
}

variable "aws_profile" {
  description = "AWS profile to use"
  type        = string
  default     = "platform-admin"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "zama-api-platform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "terraform_state_bucket" {
  description = "S3 bucket name for Terraform state"
  type        = string
}

# Application Configuration
variable "api_image_uri" {
  description = "Docker image URI for the Go API service"
  type        = string
  default     = "flentier/demo-go-api-kong:latest"
}

variable "api_port" {
  description = "Port for the Go API service"
  type        = number
  default     = 8080
}

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
