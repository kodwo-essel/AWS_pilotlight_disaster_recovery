terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_ses_email_identity" "this" {
  email = var.email_identity
}
