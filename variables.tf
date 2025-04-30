variable "primary_region" {
  type = string
}

variable "secondary_region" {
  type = string
  
}

variable "private_subnet_cidrs" {
  type = list(string)
  
}

variable "public_subnet_cidrs" {
  type = list(string)
  
}

variable "vpc_name" {
  type = string
  
}
variable "vpc_cidr" {
  type = string
  
}

variable "ec2_name" {
  type = string
  
}

# variable "keypair_name" {
#   type = string
  
# }

variable "instance_type" {
  type = string
  
}

variable "primary_asg_desired_capacity" {
  type = string
}

variable "primary_asg_max_size" {
  type = string
}

variable "primary_asg_min_size" {
  type = string
}

variable "secondary_asg_desired_capacity" {
  type = string
}

variable "secondary_asg_max_size" {
  type = string
}

variable "secondary_asg_min_size" {
  type = string
}


variable "alb_name" {
  type = string
}

variable "rds_name" {
  type = string
  
}

variable "rds_db_username" {
  type = string
  
}

variable "rds_db_password" {
  type      = string
  sensitive = true
  
}

variable "rds_engine_version" {
  type = string
}

variable "rds_db_name" {
    type = string
    
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
  
}

variable "s3_bucket_prefix" {
  type = string
}

variable "replica_ami_name" {
  type = string
}

variable "ecr_name" {
  type = string
  
}

variable "vite_public_api_url" {
  type = string
}

variable "rds_port" {
  type = string
}

variable "primary_backend_image_uri" {
  type = string
}

variable "primary_frontend_image_uri" {
  type = string
}

variable "secondary_backend_image_uri" {
  type = string
}

variable "secondary_frontend_image_uri" {
  type = string
}

variable "email_address" {
  type = string
}