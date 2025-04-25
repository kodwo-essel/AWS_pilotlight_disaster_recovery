output "primary_instance_id" {
  value = aws_db_instance.primary.id
}

output "primary_instance_identifier" {
  value = aws_db_instance.primary.identifier
  
}
output "read_replica_identifier" {
  value = aws_db_instance.read_replica.identifier
}

output "database_name" {
  value = aws_db_instance.primary.db_name
  
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
