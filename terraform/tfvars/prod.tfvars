vpc_name = "deploy-react-app-prod"
instance_name = "react-app-prod"
instance_type = "t3.large"
ami_id = "ami-0c02fb55956c7d316"
region = "us-east-1"
environment = "prod"

# Auto Scaling Configuration
min_size = 3
max_size = 10
desired_capacity = 3

# Cost Management
budget_limit = 500
alert_emails = ["your@company.com", "yourfinancedept@company.com"]

# Secrets (use AWS Secrets Manager in production)
database_password = "your_db_password"
api_key = "your_api_key"
jwt_secret = "replace_with_your_key"
slack_webhook_url = "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
