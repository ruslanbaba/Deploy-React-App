output "budget_name" {
  description = "Name of the cost budget"
  value       = aws_budgets_budget.monthly_cost.name
}

output "anomaly_detector_arn" {
  description = "ARN of the cost anomaly detector"
  value       = aws_ce_anomaly_detector.service_monitor.arn
}

output "dashboard_url" {
  description = "URL of the cost monitoring dashboard"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.cost_dashboard.dashboard_name}"
}
