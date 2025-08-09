# Terraform Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.compute.alb_dns_name
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cdn.cloudfront_domain_name
}

output "dashboard_url" {
  description = "URL of the CloudWatch monitoring dashboard"
  value       = module.monitoring.dashboard_url
}

output "cost_dashboard_url" {
  description = "URL of the cost monitoring dashboard"
  value       = module.cost_management.dashboard_url
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = module.notifications.sns_topic_arn
}
