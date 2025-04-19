variable "name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "tags" {
  description = "Tags for the ECR repository"
  type        = map(string)
  default     = {}
}


variable "region" {
  description = "AWS region"
  type        = string
}

variable "docker_context" {
  description = "Path to Docker build context (e.g., . or ./lambda)"
  type        = string
  default     = "."
}
