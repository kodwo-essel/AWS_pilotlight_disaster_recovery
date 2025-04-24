output "replica_ecr_uris" {
  value = {
    trigger     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.replica_region}.amazonaws.com/${var.prefix_filter}:latest"
    frontend = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.replica_region}.amazonaws.com/${var.prefix_filter}-frontend:latest"
    backend  = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.replica_region}.amazonaws.com/${var.prefix_filter}-backend:latest"
  }

  description = "Replica ECR URIs for core, frontend, and backend repos"
}
