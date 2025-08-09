vpc_name = "deploy-react-app-qa"
instance_name = "react-app-qa"
instance_type = "t3.small"
ami_id = "ami-0c02fb55956c7d316"
region = "us-east-1"
environment = "qa"

# Auto Scaling Configuration
min_size = 2
max_size = 5
desired_capacity = 2

# Cost Management
budget_limit = 100
alert_emails = ["devops@company.com", "qa-team@company.com"]

# Secrets (use secure values in production)
database_password = "qa-password-123"
api_key = "qa-api-key-456"
jwt_secret = "qa-jwt-secret-789"
slack_webhook_url = ""
