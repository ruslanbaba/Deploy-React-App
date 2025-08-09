variable "origin_domain_name" {
  description = "Domain name of the origin (ALB DNS name)"
  type        = string
}

variable "waf_web_acl_id" {
  description = "WAF Web ACL ID to associate with CloudFront"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "enable_s3_origin" {
  description = "Enable S3 origin for static assets"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
