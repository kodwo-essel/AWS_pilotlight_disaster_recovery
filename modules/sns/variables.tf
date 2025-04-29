variable "name" {
  type = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke (can be in a different region)"
  type        = string
}