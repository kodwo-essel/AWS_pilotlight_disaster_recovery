output "primary_instance_id" {
  value = aws_db_instance.primary.id
}

output "read_replica_id" {
  value = aws_db_instance.read_replica.id
}

output "rds_endpoint" {
  value = aws_db_instance.primary.endpoint
}

output "read_replica_endpoint" {
  value = aws_db_instance.read_replica.endpoint
}

output "rds_security_group_id" {
  value = aws_security_group.rds.id
}
