variable "name" {}
variable "namespace" {}
variable "metric_name" {}
variable "threshold" {}
variable "sns_forwarder_arn" {}
variable "dimensions" {
  description = "Dimensions for the CloudWatch Alarm"
  type        = map(string)
  default     = {}
}
