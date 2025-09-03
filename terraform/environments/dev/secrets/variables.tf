# Variables for Secrets Management

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

# Security Configuration
variable "demo_api_key" {
  description = "Demo API key for testing with Kong Konnect"
  type        = string
  sensitive   = true
  default     = "demo-api-key-12345"
}
