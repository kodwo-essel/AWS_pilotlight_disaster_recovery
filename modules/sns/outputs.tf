output "sns_arn" {
  value = aws_sns_topic.alarm_forwarder.arn
}