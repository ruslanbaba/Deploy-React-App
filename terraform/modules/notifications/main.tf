# SNS Topic for alerts and notifications
resource "aws_sns_topic" "alerts" {
  name = "${var.environment}-react-app-alerts"
  
  tags = var.common_tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "alerts" {
  arn = aws_sns_topic.alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = [
            "cloudwatch.amazonaws.com",
            "budgets.amazonaws.com",
            "events.amazonaws.com"
          ]
        }
        Action = [
          "SNS:Publish"
        ]
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# Lambda function for Slack notifications
resource "aws_lambda_function" "slack_notifier" {
  count = var.slack_webhook != "" ? 1 : 0
  
  filename         = data.archive_file.lambda_zip[0].output_path
  function_name    = "${var.environment}-slack-notifier"
  role            = aws_iam_role.lambda_role[0].arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  runtime         = "python3.9"
  timeout         = 60

  environment {
    variables = {
      SLACK_WEBHOOK_URL = var.slack_webhook
    }
  }

  tags = var.common_tags
}

# Lambda code archive
data "archive_file" "lambda_zip" {
  count = var.slack_webhook != "" ? 1 : 0
  
  type        = "zip"
  output_path = "/tmp/slack_notifier.zip"
  
  source {
    content = templatefile("${path.module}/lambda/slack_notifier.py", {
      webhook_url = var.slack_webhook
    })
    filename = "index.py"
  }
}

# Lambda IAM role
resource "aws_iam_role" "lambda_role" {
  count = var.slack_webhook != "" ? 1 : 0
  
  name = "${var.environment}-slack-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Lambda IAM policy
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  count = var.slack_webhook != "" ? 1 : 0
  
  role       = aws_iam_role.lambda_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# SNS subscription to Lambda
resource "aws_sns_topic_subscription" "lambda" {
  count = var.slack_webhook != "" ? 1 : 0
  
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.slack_notifier[0].arn
}

# Lambda permission for SNS
resource "aws_lambda_permission" "allow_sns" {
  count = var.slack_webhook != "" ? 1 : 0
  
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.slack_notifier[0].function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alerts.arn
}
