terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

resource "aws_ecr_repository" "this" {
  name                 = var.name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images older than 30 days"
        selection = {
          tagStatus     = "untagged"
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.this.repository_url}
      docker build -t ${var.name} ${var.docker_context}
      docker tag ${var.name}:latest ${aws_ecr_repository.this.repository_url}:latest
      docker push ${aws_ecr_repository.this.repository_url}:latest
    EOT
  }

  triggers = {
    image_version = timestamp()  # Forces re-run on every apply
  }

  depends_on = [aws_ecr_repository.this]
}


# resource "aws_ecr_replication_configuration" "replication" {
#   replication_configuration {
#     rule {
#       destination {
#         region      = var.replica_region
#         registry_id = data.aws_caller_identity.current.account_id
#       }

#       # Optional: Filter which repositories to replicate
#       repository_filter {
#         filter      = var.name
#         filter_type = "PREFIX_MATCH" # Or "TAG_PREFIX_MATCH"
#       }
#     }
#   }
# }

