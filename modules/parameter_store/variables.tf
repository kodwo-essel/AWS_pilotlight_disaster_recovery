# modules/parameter-store/variables.tf
variable "parameters" {
  description = "List of parameters to create in AWS Parameter Store"
  type = list(object({
    name        = string
    type        = string
    value       = string
    description = optional(string)
    key_id      = optional(string)
    tags        = optional(map(string), {})
  }))
  default = []
}

variable "default_tags" {
  description = "Default tags to apply to all parameters"
  type        = map(string)
  default     = {}
}