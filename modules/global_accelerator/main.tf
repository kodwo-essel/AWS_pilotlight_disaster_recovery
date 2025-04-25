terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_globalaccelerator_accelerator" "main" {
  name            = var.accelerator_name
  ip_address_type = "IPV4"
  enabled         = true
}

resource "aws_globalaccelerator_listener" "main" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol        = "TCP"

  port_range {
    from_port = 80
    to_port   = 80
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.primary_region
  traffic_dial_percentage = 100
  health_check_port       = 80
  health_check_protocol   = "HTTP"
  health_check_path       = "/"

  endpoint_configuration {
    endpoint_id = var.primary_alb_arn
    weight      = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn            = aws_globalaccelerator_listener.main.id
  endpoint_group_region   = var.secondary_region
  traffic_dial_percentage = 0
  health_check_port       = 80
  health_check_protocol   = "HTTP"
  health_check_path       = "/"

  endpoint_configuration {
    endpoint_id = var.secondary_alb_arn
    weight      = 100
  }
}