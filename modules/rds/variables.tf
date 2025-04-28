variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "primary_vpc_id" {
  description = "VPC ID for the RDS and security group"
  type        = string
}

variable "primary_subnet_ids" {
  description = "Subnets for RDS subnet group"
  type        = list(string)
}

variable "replica_vpc_id" {
  description = "VPC ID for the replica region"
  type = string
}

variable "replica_subnet_ids" {
  description = "Subnets for RDS Replica subnet group"
  type = list(string)
  
}
variable "allocated_storage" {
  type        = number
  default     = 20
}

variable "engine_version" {
  type        = string
  default     = "15.3"
}

variable "instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "username" {
  type        = string
}

variable "password" {
  type        = string
  sensitive   = true
}

variable "primary_az" {
  type        = string
}

variable "replica_region" {
  type        = string
}

variable "replica_az" {
  type        = string
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to access RDS (e.g., from EC2 or ALB)"
  type        = list(string)
}

variable "db_name" {
  type = string
  
}