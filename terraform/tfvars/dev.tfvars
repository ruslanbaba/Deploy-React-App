vpc_name = "deploy-react-app-dev"
instance_name = "react-app-dev"
instance_type = "t3.micro"
ami_id = "ami-0c02fb55956c7d316"
region = "us-east-1"
environment = "dev"

# Auto Scaling Configuration
min_size = 1
max_size = 3
desired_capacity = 1

# Cost Management
budget_limit = 50
alert_emails = ["devops@company.com"]

# Secrets (use secure values in production)
database_password = "dev-password-123"
api_key = "dev-api-key-456"
jwt_secret = "dev-jwt-secret-789"
slack_webhook_url = ""
