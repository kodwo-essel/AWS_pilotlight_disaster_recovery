terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "${var.name}-instance-profile"
  role = var.iam_role_name
}