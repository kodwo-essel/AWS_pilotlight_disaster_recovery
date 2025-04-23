# modules/parameter-store/outputs.tf
output "parameter_arns" {
  description = "Map of parameter names to their ARNs"
  value = {
    for name, param in aws_ssm_parameter.parameter : name => param.arn
  }
}

output "parameter_names" {
  description = "List of parameter names created"
  value       = [for param in aws_ssm_parameter.parameter : param.name]
}
