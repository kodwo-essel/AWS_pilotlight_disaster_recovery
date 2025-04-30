terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_sns_topic" "alarm_forwarder" {
  name = "${var.name}-sns-topic"
}

resource "aws_sns_topic_policy" "cloudwatch_publish_policy" {
  arn    = aws_sns_topic.alarm_forwarder.arn
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "AllowCloudWatch",
      Effect    = "Allow",
      Principal = {
        Service = "cloudwatch.amazonaws.com"
      },
      Action    = "SNS:Publish",
      Resource  = aws_sns_topic.alarm_forwarder.arn
    }]
  })
}

# Add the cross-region subscription
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.alarm_forwarder.arn
  protocol  = "lambda"
  endpoint  = var.lambda_function_arn  # ARN of the Lambda function in another region
}

resource "aws_sns_topic_subscription" "email_alert" {
  topic_arn = aws_sns_topic.alarm_forwarder.arn
  protocol  = "email"
  endpoint  = "jimmy.essel@amalitech.com"  # Replace with your email
}