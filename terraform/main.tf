# Network Module
module "network" {
  source = "./modules/network"
  
  vpc_name         = var.vpc_name
  vpc_cidr         = "10.0.0.0/16"
  azs              = ["us-east-1a", "us-east-1b"]
  public_subnets   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets  = ["10.0.11.0/24", "10.0.12.0/24"]
  database_subnets = ["10.0.21.0/24", "10.0.22.0/24"]
  
  common_tags = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"
  
  sg_name    = "react-app-sg"
  vpc_id     = module.network.vpc_id
  vpc_cidr   = module.network.vpc_cidr_block
  waf_name   = "${var.environment}-react-app-waf"
  
  common_tags = local.common_tags
}

# Compute Module
module "compute" {
  source = "./modules/compute"
  
  instance_name       = var.instance_name
  subnet_ids          = module.network.private_subnets
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  alb_name            = "${var.environment}-react-app-alb"
  alb_security_groups = [module.security.alb_security_group_id]
  
  depends_on = [module.network, module.security]
}

# CDN Module with WAF Association
module "cdn" {
  source = "./modules/cdn"
  
  origin_domain_name = module.compute.alb_dns_name
  waf_web_acl_id     = module.security.waf_web_acl_arn
  
  depends_on = [module.compute, module.security]
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  log_group_name     = "${var.environment}-react-app-logs"
  cpu_alarm_name     = "${var.environment}-react-app-cpu-alarm"
  environment        = var.environment
  sns_topic_arn      = module.notifications.sns_topic_arn
  alb_arn_suffix     = module.compute.alb_arn_suffix
  target_group_arn   = module.compute.target_group_arn_suffix
  
  common_tags = local.common_tags
  depends_on  = [module.compute, module.notifications]
}

# Secrets Module
module "secrets" {
  source = "./modules/secrets"
  
  secret_name       = "${var.environment}-react-app-secrets"
  environment       = var.environment
  database_password = var.database_password
  api_key          = var.api_key
  jwt_secret       = var.jwt_secret
  
  app_parameters = {
    app_name    = "react-app"
    environment = var.environment
    region      = var.region
  }
  
  common_tags = local.common_tags
}

# Notifications Module (SNS/Slack)
module "notifications" {
  source = "./modules/notifications"
  
  environment   = var.environment
  slack_webhook = var.slack_webhook_url
  
  common_tags = local.common_tags
}

# Cost Management Module
module "cost_management" {
  source = "./modules/cost"
  
  environment     = var.environment
  budget_limit    = var.budget_limit
  alert_emails    = var.alert_emails
  sns_topic_arn   = module.notifications.sns_topic_arn
  
  common_tags = local.common_tags
  depends_on  = [module.notifications]
}

# Local values
locals {
  common_tags = {
    Environment = var.environment
    Project     = "react-app"
    Owner       = "devops-team"
    CreatedBy   = "terraform"
    CreatedAt   = timestamp()
  }
}
