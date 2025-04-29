terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "this" {
  alarm_name                = var.name
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 1
  metric_name              = var.metric_name
  namespace                = var.namespace
  period                   = 60
  statistic                = "Maximum"
  threshold                = var.threshold
  alarm_description        = "Alarm when ${var.metric_name} exceeds threshold"
  alarm_actions            = [var.sns_forwarder_arn]

  treat_missing_data = "breaching"

  dimensions = var.dimensions
}
