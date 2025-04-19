output "repository_url" {
  value       = aws_ecr_repository.this.repository_url
  description = "ECR repository URL"
}

output "image_url" {
  value       = "${aws_ecr_repository.this.repository_url}:latest"
  description = "Full Docker image URL including the :latest tag"
}