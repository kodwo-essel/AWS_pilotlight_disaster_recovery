terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}


provider "aws" {
    alias = "primary"
    region = var.primary_region 
}

provider "aws" {
    alias = "secondary"
    region = var.secondary_region
  
}

# PRIMARY VPC SETUP
module "primary_vpc" {
    source = "./modules/vpc"
    providers = {
        aws = aws.primary
    }
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
    name                = var.vpc_name
    vpc_cidr            = var.vpc_cidr
}

# SECONDARY VPC SETUP
module "secondary_vpc" {
    source = "./modules/vpc"
    providers = {
        aws = aws.secondary
    }
    private_subnet_cidrs = var.private_subnet_cidrs
    public_subnet_cidrs  = var.public_subnet_cidrs
    name                = var.vpc_name
    vpc_cidr            = var.vpc_cidr
}

# PRIMARY EC2 INSTANCE FOR AMI CREATION
data "aws_ami" "ubuntu" {
  provider = aws.primary
  most_recent = true
  owners      = ["099720109477"]  # Ubuntu owner ID
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }
}

# PRIMARY SECURITY GROUP
module "primary_sg" {
    source = "./modules/security_group"
    providers = {
        aws = aws.primary
    }
    vpc_id = module.primary_vpc.vpc_id
    name = "${var.ec2_name}-sg"
}


# SECONDARY SECURITY GROUP
module "secondary_sg" {
    source = "./modules/security_group"
    providers = {
        aws = aws.secondary
    }
    vpc_id = module.secondary_vpc.vpc_id
    name = "${var.ec2_name}-sg"
}

module "ec2" {
    source = "./modules/ec2"
    providers = {
        aws = aws.primary
    }
    name = var.ec2_name
    # key_name        = var.keypair_name
    ami_id          = data.aws_ami.ubuntu.id
    instance_type   = var.instance_type
    vpc_id = module.primary_vpc.vpc_id
    subnet_id       = module.primary_vpc.public_subnet_ids[0]
    security_group_ids = [module.primary_sg.security_group_id]
}

# AMI CREATION FROM PRIMARY EC2 INSTANCE
module "ami_from_ec2" {
    source = "./modules/ami_from_ec2"
    providers = {
        aws.primary = aws.primary
        aws.secondary = aws.secondary
    }
    instance_id = module.ec2.instance_id
    ami_name    = var.replica_ami_name
    source_region = var.primary_region

    depends_on = [module.ec2]
  
}

# TERMINATE EC2 AFTER AMI HAS BEEN CREATED FROM IT
resource "null_resource" "terminate_ec2" {
  depends_on = [module.ami_from_ec2]
  
  triggers = {
    primary_ami_id = module.ami_from_ec2.primary_ami_id
    secondary_ami_id = module.ami_from_ec2.secondary_ami_id
    instance_id = module.ec2.instance_id
    region = var.primary_region
  }
  
  # When this resource is created (after AMIs are ready)
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids ${self.triggers.instance_id} --region ${self.triggers.region}"
  }
}


# SECONDARY EC2 INSTANCE
# module "secondary_ec2" {
#     source = "./modules/ec2"
#     providers = {
#         aws = aws.secondary
#     }
#     name = var.ec2_name
#     key_name        = var.keypair_name
#     ami_id          = var.secondary_ami_id
#     instance_type   = var.instance_type
#     vpc_id = module.secondary_vpc.vpc_id
#     subnet_id       = module.secondary_vpc.public_subnet_ids[0]
# }

# PRIMARY AUTO SCALING GROUP
module "primary_asg" {
    source = "./modules/asg"
    providers = {
        aws = aws.primary
    }
    name = var.ec2_name
    key_name        = var.keypair_name
    ami_id          = module.ami_from_ec2.primary_ami_id
    instance_type   = var.instance_type
    vpc_id = module.primary_vpc.vpc_id
    subnet_ids       = module.primary_vpc.public_subnet_ids

    desired_capacity = var.primary_asg_desired_capacity
    min_size         = var.primary_asg_min_size
    max_size         = var.primary_asg_max_size

    target_group_arns = [module.primary_alb.target_group_arn]

}

# SECONDARY AUTO SCALING GROUP
module "secondary_asg" {
    source = "./modules/asg"
    providers = {
        aws = aws.secondary
    }
    name = var.ec2_name
    key_name        = var.keypair_name
    ami_id          = module.ami_from_ec2.secondary_ami_id
    instance_type   = var.instance_type
    vpc_id = module.secondary_vpc.vpc_id
    subnet_ids       = module.secondary_vpc.public_subnet_ids

    desired_capacity = var.secondary_asg_desired_capacity
    min_size         = var.secondary_asg_min_size
    max_size         = var.secondary_asg_max_size

    target_group_arns = [module.secondary_alb.target_group_arn]
}

# PRIMARY APPLICATION LOAD BALANCER

module "primary_alb" {
    source = "./modules/alb"
    providers = {
        aws = aws.primary
    }
    name                = var.alb_name
    vpc_id              = module.primary_vpc.vpc_id
    subnet_ids          = module.primary_vpc.public_subnet_ids
    security_group_id   = module.primary_sg.security_group_id
}

# SECONDARY APPLICATION LOAD BALANCER
module "secondary_alb" {
    source = "./modules/alb"
    providers = {
        aws = aws.secondary
    }
    name                = var.alb_name
    vpc_id              = module.secondary_vpc.vpc_id
    subnet_ids          = module.secondary_vpc.public_subnet_ids
    security_group_id   = module.secondary_sg.security_group_id
}

# RDS WITH CROSS REGION REPLICA
module "rds" {
    source = "./modules/rds"
    providers = {
        aws = aws.primary
    }
    name                = var.rds_name
    vpc_id              = module.primary_vpc.vpc_id
    subnet_ids          = module.primary_vpc.private_subnet_ids
    engine_version = var.rds_engine_version
    primary_az = module.primary_vpc.availability_zones[0]
    replica_region = var.secondary_region
    replica_az = module.secondary_vpc.availability_zones[0]
    instance_class   = var.rds_instance_class
    allocated_storage    = var.rds_allocated_storage
    username         = var.rds_db_username
    password = var.rds_db_password
    allowed_cidrs = [module.primary_vpc.vpc_cidr]
}


# S3 WITH CROSS REGION REPLICATION
module "s3" {
    source = "./modules/s3"
    providers = {
      aws = aws.primary
    }
    replica_region = var.secondary_region
    bucket_prefix = var.s3_bucket_prefix
  
}