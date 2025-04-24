terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}


resource "aws_ami_from_instance" "this" {
  provider = aws.primary
  name               = var.ami_name
  source_instance_id = var.instance_id
  description        = "AMI from instance ${var.instance_id}"
  tags = {
    Name = "${var.ami_name}-primary"
  }
}

resource "aws_ami_copy" "copy" {
  provider          = aws.secondary
  name              = "${var.ami_name}-copy"
  description       = "DR Copy of AMI"
  source_ami_id     = aws_ami_from_instance.this.id
  source_ami_region = var.source_region
}
