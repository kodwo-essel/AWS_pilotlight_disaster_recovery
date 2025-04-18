variable "instance_id" {
  description = "ID of the EC2 instance to create AMI from"
  type        = string
}

variable "ami_name" {
  description = "Base name of the AMI"
  type        = string
}

variable "source_region" {
  type = string
}
