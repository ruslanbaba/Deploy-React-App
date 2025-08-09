# CloudFront Distribution with WAF association
resource "aws_cloudfront_distribution" "cdn" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = "react-app-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  
  # Associate WAF Web ACL
  web_acl_id = var.waf_web_acl_id

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "react-app-origin"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  # Cache behavior for static assets
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "react-app-origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = var.price_class

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = var.common_tags
}

# CloudFront Origin Access Control for S3 (if using S3 for static assets)
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  count = var.enable_s3_origin ? 1 : 0
  
  name                              = "react-app-s3-oac"
  description                       = "Origin Access Control for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# S3 bucket for static assets (optional)
resource "aws_s3_bucket" "static_assets" {
  count = var.enable_s3_origin ? 1 : 0
  
  bucket = "${var.environment}-react-app-static-${random_id.bucket_suffix[0].hex}"

  tags = var.common_tags
}

resource "random_id" "bucket_suffix" {
  count = var.enable_s3_origin ? 1 : 0
  
  byte_length = 4
}

resource "aws_s3_bucket_public_access_block" "static_assets" {
  count = var.enable_s3_origin ? 1 : 0
  
  bucket = aws_s3_bucket.static_assets[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "static_assets" {
  count = var.enable_s3_origin ? 1 : 0
  
  bucket = aws_s3_bucket.static_assets[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
