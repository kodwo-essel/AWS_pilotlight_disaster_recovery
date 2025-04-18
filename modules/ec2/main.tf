terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  # key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip

  user_data              = file("${path.module}/user_data.sh")


  tags = {
    Name = var.name
  }
}
