# AWS Budget with alerts
resource "aws_budgets_budget" "monthly_cost" {
  name       = "${var.environment}-monthly-budget"
  budget_type = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  time_period_start = "2024-01-01_00:00"

  cost_filters = {
    Tag = ["Environment:${var.environment}"]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
    subscriber_sns_topic_arns  = [var.sns_topic_arn]
  }

  tags = var.common_tags
}

# Cost Anomaly Detector
resource "aws_ce_anomaly_detector" "service_monitor" {
  name = "${var.environment}-service-anomaly-detector"
  monitor_type = "DIMENSIONAL"

  specification = jsonencode({
    Dimension = "SERVICE"
    MatchOptions = ["EQUALS"]
    Values = ["Amazon Elastic Compute Cloud - Compute", "Amazon Simple Storage Service"]
  })

  tags = var.common_tags
}

# Cost Anomaly Subscription
resource "aws_ce_anomaly_subscription" "alerts" {
  name      = "${var.environment}-cost-anomaly-alerts"
  frequency = "DAILY"
  
  monitor_arn_list = [
    aws_ce_anomaly_detector.service_monitor.arn
  ]
  
  subscriber {
    type    = "EMAIL"
    address = length(var.alert_emails) > 0 ? var.alert_emails[0] : "admin@example.com"
  }

  threshold_expression {
    and {
      dimension {
        key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
        values        = ["100"]
        match_options = ["GREATER_THAN_OR_EQUAL"]
      }
    }
  }

  tags = var.common_tags
}

# CloudWatch Dashboard for Cost Monitoring
resource "aws_cloudwatch_dashboard" "cost_dashboard" {
  dashboard_name = "${var.environment}-cost-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Billing", "EstimatedCharges", "Currency", "USD"]
          ]
          period = 86400
          stat   = "Maximum"
          region = "us-east-1"
          title  = "Estimated Monthly Charges"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization"],
            ["AWS/ApplicationELB", "RequestCount"],
            ["AWS/ApplicationELB", "TargetResponseTime"]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "Application Performance Metrics"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Resource tagging policy for cost allocation
resource "aws_organizations_policy" "cost_allocation_tags" {
  count = var.enable_cost_allocation_tags ? 1 : 0
  
  name        = "${var.environment}-cost-allocation-policy"
  description = "Policy to enforce cost allocation tags"
  type        = "TAG_POLICY"

  content = jsonencode({
    tags = {
      Environment = {
        tag_key = "Environment"
        enforced_for = ["all"]
        tag_value = {
          "@@assign" = ["dev", "qa", "prod"]
        }
      }
      Project = {
        tag_key = "Project"
        enforced_for = ["all"]
      }
      Owner = {
        tag_key = "Owner"
        enforced_for = ["all"]
      }
    }
  })

  tags = var.common_tags
}
