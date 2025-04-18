output "primary_ami_id" {
  value = aws_ami_from_instance.this.id
}

output "secondary_ami_id" {
  value = aws_ami_copy.copy.id
}
