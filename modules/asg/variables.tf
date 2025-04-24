variable "name" {
  description = "Base name for ASG resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the launch template"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# variable "key_name" {
#   description = "Key pair name"
#   type        = string
# }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for ASG"
  type        = list(string)
}

variable "desired_capacity" {
  description = "Desired number of instances"
  type        = number
}

variable "min_size" {
  description = "Minimum number of instances"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances"
  type        = number
}

variable "target_group_arns" {
  description = "List of ALB target group ARNs (optional)"
  type        = list(string)
  default     = []
}


variable "ecr_name" {
  type = string
}
variable "frontend_image_uri" {
  type = string
}
variable "backend_image_uri" {
  type = string
  
}

variable "s3_bucket_name" {
  type = string
}

variable "path_to_docker_compose" {
  type = string
}

variable "iam_role_name" {
  type = string
}