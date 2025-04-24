terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_ecr_replication_configuration" "this" {
  replication_configuration {
    rule {
      destination {
        region      = var.replica_region
        registry_id = data.aws_caller_identity.current.account_id
      }

      repository_filter {
        filter      = var.prefix_filter
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}
