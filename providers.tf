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