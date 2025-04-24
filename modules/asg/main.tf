terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# ASG IAM ROLE
resource "aws_iam_role" "asg_instance_role" {
  name = "${var.name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_policy" {
  name = "${var.name}-ssm-read-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_pull_policy" {
  name = "${var.name}-ecr-pull-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_read_policy" {
  name        = "${var.name}-s3-read-policy"
  description = "Allow EC2 instances to read from the S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow"
        Action    = "s3:GetObject"
        Resource  = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecr_pull_attach" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = aws_iam_policy.ecr_pull_policy.arn
}

resource "aws_iam_role_policy_attachment" "s3_read_attach" {
  role       = aws_iam_role.asg_instance_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}



resource "aws_security_group" "asg_sg" {
  name   = "${var.name}-asg-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-asg-sg"
  }
}


resource "aws_iam_instance_profile" "asg_instance_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.asg_instance_role.name
}


resource "aws_launch_template" "this" {
  name_prefix   = "${var.name}-lt"
  image_id      = var.ami_id
  instance_type = var.instance_type
  # key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  iam_instance_profile {
    name = aws_iam_instance_profile.asg_instance_profile.name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    ecr_name = var.ecr_name,
    FRONTEND_IMAGE_URI = var.frontend_image_uri,
    BACKEND_IMAGE_URI = var.backend_image_uri,
    S3_BUCKET_NAME=var.s3_bucket_name,
    PATH_TO_DOCKER_COMPOSE=var.path_to_docker_compose,
    ACCOUNT_ID = data.aws_caller_identity.current.account_id,
    AWS_REGION = data.aws_region.current.name
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name}-asg-instance"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "this" {
  name                      = "${var.name}-asg"
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  min_size                  = var.min_size
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = "EC2"
  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-asg-instance"
    propagate_at_launch = true
  }

  target_group_arns = var.target_group_arns

  lifecycle {
    create_before_destroy = true
  }
}
