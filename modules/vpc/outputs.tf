output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

# availability zones in region
data "aws_availability_zones" "available_zones" {
  state = "available"
}

output "availability_zones" {
  value = data.aws_availability_zones.available_zones.names
}