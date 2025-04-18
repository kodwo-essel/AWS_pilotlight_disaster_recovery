variable "name" {
  description = "Name tag and base name for resources"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

# variable "key_name" {
#   description = "Key pair name to SSH into the instance"
#   type        = string
# }

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch instance in"
  type        = string
}

variable "associate_public_ip" {
  description = "Whether to assign public IP to instance"
  type        = bool
  default     = true
}


variable "security_group_ids" {
  description = "List of security group IDs to associate with the instance"
  type        = list(string)
  default     = []
  
}