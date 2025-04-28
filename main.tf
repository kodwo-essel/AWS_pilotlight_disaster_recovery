terraform {

    backend "s3" {
        bucket         = "pilot-light-state-bucket"
        key            = "dr/terraform.tfstate"
        region         = "eu-west-1"
        encrypt        = true
        use_lockfile   = true
    }

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
data "aws_ami" "amazon_linux" {
  
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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
    ami_id          = data.aws_ami.amazon_linux.id
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

# IAM ROLE FOR AUTO SCALING GROUP
module "asg_iam_role" {
  source = "./modules/asg_iam_role"
  providers = {
    aws = aws.primary
  }
  name = var.ec2_name
  
}

# INSTANCE PROFILE
module "instance_profile" {
    source = "./modules/instance_profile"
    providers = {
        aws = aws.primary
    }
    name = var.ec2_name
    iam_role_name = module.asg_iam_role.role_name
}
# PRIMARY AUTO SCALING GROUP
module "primary_asg" {
    source = "./modules/asg"
    providers = {
        aws = aws.primary
    }
    name = var.ec2_name
    # key_name        = var.keypair_name
    ami_id          = module.ami_from_ec2.primary_ami_id
    instance_type   = var.instance_type
    vpc_id = module.primary_vpc.vpc_id
    subnet_ids       = module.primary_vpc.public_subnet_ids
    ecr_name = var.ecr_name
    frontend_image_uri = var.primary_frontend_image_uri
    backend_image_uri = var.primary_backend_image_uri
    s3_bucket_name = module.s3.source_bucket
    path_to_docker_compose = "docker-compose.yml"
    iam_role_name = module.asg_iam_role.role_name
    instance_profile_name = module.instance_profile.instance_profile_name

    desired_capacity = var.primary_asg_desired_capacity
    min_size         = var.primary_asg_min_size
    max_size         = var.primary_asg_max_size

    target_group_arns = [module.primary_alb.frontend_target_group_arn, module.primary_alb.backend_target_group_arn]

    depends_on = [ module.primary_parameter_store, module.rds, module.s3, aws_s3_object.docker_compose ]

}

# SECONDARY AUTO SCALING GROUP
module "secondary_asg" {
    source = "./modules/asg"
    providers = {
        aws = aws.secondary
    }
    name = var.ec2_name
    # key_name        = var.keypair_name
    ami_id          = module.ami_from_ec2.secondary_ami_id
    instance_type   = var.instance_type
    vpc_id = module.secondary_vpc.vpc_id
    subnet_ids       = module.secondary_vpc.public_subnet_ids
    ecr_name = var.ecr_name
    frontend_image_uri = var.secondary_backend_image_uri
    backend_image_uri = var.secondary_frontend_image_uri
    s3_bucket_name = module.s3.replica_bucket
    path_to_docker_compose = "docker-compose.yml"
    iam_role_name = module.asg_iam_role.role_name
    instance_profile_name = module.instance_profile.instance_profile_name

    desired_capacity = var.secondary_asg_desired_capacity
    min_size         = var.secondary_asg_min_size
    max_size         = var.secondary_asg_max_size

    target_group_arns = [module.secondary_alb.frontend_target_group_arn, module.secondary_alb.backend_target_group_arn]

    depends_on = [ module.secondary_parameter_store, module.rds, module.s3, aws_s3_object.docker_compose ]
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
    primary_vpc_id              = module.primary_vpc.vpc_id
    replica_vpc_id = module.secondary_vpc.vpc_id
    primary_subnet_ids          = module.primary_vpc.private_subnet_ids
    replica_subnet_ids = module.secondary_vpc.private_subnet_ids
    engine_version = var.rds_engine_version
    primary_az = module.primary_vpc.availability_zones[0]
    replica_region = var.secondary_region
    replica_az = module.secondary_vpc.availability_zones[0]
    instance_class   = var.rds_instance_class
    allocated_storage    = var.rds_allocated_storage
    username         = var.rds_db_username
    password = var.rds_db_password
    db_name = var.rds_db_name
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

# PUSH DOCKER COMPOSE FILE TO S3
resource "aws_s3_object" "docker_compose" {
  provider = aws.primary

  bucket = module.s3.source_bucket
  key    = "docker-compose.yml"
  source = "./docker-compose.yml"

  depends_on = [ module.s3 ]
}

module "ecr" {
  source         = "./modules/ecr"
  providers = {
    aws = aws.primary
  }
  name           = var.ecr_name
  region         = var.primary_region
  replica_region = var.secondary_region
  docker_context = "./modules/lambda/function"
  tags = {
    Project = "Failover"
    Env     = "prod"
  }
}

# module "frontend_ecr" {
#   source         = "./modules/ecr"
#   providers = {
#     aws = aws.primary
#   }
#   name           = "${var.ecr_name}-frontend"
#   region         = var.primary_region
#   replica_region = var.secondary_region
#   docker_context = "./frontend"
#   tags = {
#     Project = "Failover"
#     Env     = "prod"
#   }
# }

# module "backend_ecr" {
#   source         = "./modules/ecr"
#   providers = {
#     aws = aws.primary
#   }
#   name           = "${var.ecr_name}-backend"
#   region         = var.primary_region
#   replica_region = var.secondary_region
#   docker_context = "./backend"
#   tags = {
#     Project = "Failover"
#     Env     = "prod"
#   }
# }


# ECR REPLICATION
module "ecr_replication" {
  source         = "./modules/ecr_replication"

  providers = {
    aws = aws.primary
  }

  prefix_filter  = var.ecr_name             
  replica_region = var.secondary_region    
}


# PRIMARY PARAMETER STORE FOR CREDENTIALS STORAGE
module "primary_parameter_store" {
  source = "./modules/parameter_store"
  providers = {
    aws = aws.primary
  }

  parameters = [
    # React Frontend Parameters
    {
      name        = "/${var.ecr_name}-frontend/VITE_PUBLIC_API_URL"
      type        = "String"
      value       = var.vite_public_api_url
      tags        = { Component = "frontend" }
    },
    # Spring Boot Backend Parameters
    {
      name        = "/${var.ecr_name}-backend/S3_BUCKET_REGION"
      type        = "String"
      value       = var.primary_region # Replace with your region
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/S3_BUCKET_NAME"
      type        = "String"
      value       = module.s3.source_bucket
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_HOST"
      type        = "String"
      value       = module.rds.rds_endpoint
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_PORT"
      type        = "String"
      value       = var.rds_port
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_NAME"
      type        = "String"
      value       = module.rds.database_name
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_USERNAME"
      type        = "String"
      value       = var.rds_db_username
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_PASSWORD"
      type        = "SecureString"
      value       = var.rds_db_password
      key_id      = "alias/aws/ssm"
      tags        = { Component = "backend" }
    }
  ]

  default_tags = {
    Project = "Failover"
    ManagedBy = "Terraform"
  }
}

# SECONDARY PARAMETER STORE FOR CREDENTIALS STORAGE
module "secondary_parameter_store" {
  source = "./modules/parameter_store"
  providers = {
    aws = aws.secondary
  }

  parameters = [
    # React Frontend Parameters
    {
      name        = "/${var.ecr_name}-frontend/VITE_PUBLIC_API_URL"
      type        = "String"
      value       = var.vite_public_api_url
      tags        = { Component = "frontend" }
    },
    # Spring Boot Backend Parameters
    {
      name        = "/${var.ecr_name}-backend/S3_BUCKET_REGION"
      type        = "String"
      value       = var.secondary_region
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/S3_BUCKET_NAME"
      type        = "String"
      value       = module.s3.replica_bucket
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_HOST"
      type        = "String"
      value       = module.rds.read_replica_endpoint
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_PORT"
      type        = "String"
      value       = var.rds_port
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_NAME"
      type        = "String"
      value       = module.rds.database_name
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_USERNAME"
      type        = "String"
      value       = var.rds_db_username
      tags        = { Component = "backend" }
    },
    {
      name        = "/${var.ecr_name}-backend/DB_PASSWORD"
      type        = "SecureString"
      value       = var.rds_db_password
      key_id      = "alias/aws/ssm"
      tags        = { Component = "backend" }
    }
  ]

  default_tags = {
    Project = "Failover"
    ManagedBy = "Terraform"
  }
}

# LAMBDA FUNCTION
module "failover_lambda" {
  source = "./modules/lambda"

  providers = {
    aws = aws.secondary
  }

  function_name = "failover-checker"
  image_uri     = module.ecr_replication.replica_ecr_uris.trigger

  environment_variables = {
    APP_HEALTH_URL        = module.primary_alb.alb_dns_name
    RETRY_COUNT           = "3"
    RETRY_INTERVAL        = "60"
    ASG_NAME              = module.secondary_asg.asg_name
    RDS_REPLICA_IDENTIFIER = module.rds.read_replica_identifier
    SECONDARY_REGION_NAME  = var.secondary_region
    PRIMARY_REGION_NAME    = var.primary_region
  }

  depends_on = [ module.primary_asg, module.secondary_asg, module.ecr, module.rds ]
}


# GLOBAL ACCELERATION
module "global_accelerator" {
  source = "./modules/global_accelerator"

  providers = {
    aws = aws.primary
  }
  primary_alb_arn = module.primary_alb.alb_arn
  secondary_alb_arn = module.secondary_alb.alb_arn
  primary_region = var.primary_region
  secondary_region = var.secondary_region
  accelerator_name = "${var.ec2_name}-global-accelerator"
}