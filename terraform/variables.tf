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