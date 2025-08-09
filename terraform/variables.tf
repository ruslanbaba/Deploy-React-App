variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "react-app-vpc"
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "react-app-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for EC2"
  type        = string
  default     = "ami-0c02fb55956c7d316"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
  default     = "dev"
}

variable "min_size" {
  description = "Minimum size of the Auto Scaling Group"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum size of the Auto Scaling Group"
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired capacity of the Auto Scaling Group"
  type        = number
  default     = 2
}

variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = "change-me-in-production"
}

variable "api_key" {
  description = "API key for external services"
  type        = string
  sensitive   = true
  default     = "change-me-in-production"
}

variable "jwt_secret" {
  description = "JWT signing secret"
  type        = string
  sensitive   = true
  default     = "change-me-in-production"
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for notifications"
  type        = string
  sensitive   = true
  default     = ""
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
}

variable "alert_emails" {
  description = "List of email addresses for cost alerts"
  type        = list(string)
  default     = []
}