# Variables for Observability Infrastructure

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

variable "log_retention_days" {
  description = "CloudWatch logs retention in days"
  type        = number
  default     = 7
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = ""
}



variable "api_port" {
  description = "Port number for the API service"
  type        = number
  default     = 8080
}
