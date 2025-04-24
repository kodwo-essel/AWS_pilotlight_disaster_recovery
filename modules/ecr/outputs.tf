output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "Source ECR repository URL"
}

output "image_url" {
  value       = "${aws_ecr_repository.this.repository_url}:latest"
  description = "Source Docker image URL including the :latest tag"
}


data "aws_caller_identity" "current" {}

output "replica_image_url" {
  value       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.replica_region}.amazonaws.com/${var.name}:latest"
  description = "Replica Docker image URL including the :latest tag"
}