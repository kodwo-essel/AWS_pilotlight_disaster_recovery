terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

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
          "ecr:BatchGetImage",
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
        Action   = [
          "s3:GetObject",       # Read
          "s3:PutObject",       # Create/Update
          "s3:DeleteObject",    # Delete
          "s3:ListBucket",      # Optional: List contents of the bucket
          "s3:GetObjectAcl",    # Optional: Read ACL
          "s3:PutObjectAcl"     # Optional: Write ACL
        ]
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