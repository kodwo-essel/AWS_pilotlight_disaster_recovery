terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}


resource "aws_security_group" "rds" {
  name        = "${var.name}-rds-sg"
  description = "Security group for RDS ${var.name}"
  vpc_id      = var.primary_vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-sg"
  }
}


# Create a security group in the replica region
resource "aws_security_group" "rds_replica" {
  provider    = aws.replica
  name        = "${var.name}-rds-replica-sg"
  description = "Security group for RDS replica ${var.name}"
  vpc_id      = var.replica_vpc_id  # You need to provide the VPC ID in the replica region

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name}-rds-replica-sg"
  }
}


resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.primary_subnet_ids

  tags = {
    Name = "${var.name}-subnet-group"
  }
}

# CREATE SUBNET GROUPS FOR THE REPLICA REGION
resource "aws_db_subnet_group" "replica" {
  provider   = aws.replica
  name       = "${var.name}-replica-subnet-group"
  subnet_ids = var.replica_subnet_ids

  tags = {
    Name = "${var.name}-replica-subnet-group"
  }
}

resource "aws_db_instance" "primary" {
  identifier              = "${var.name}-primary"
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
  db_name                 = var.db_name
  username                = var.username
  password                = var.password
  db_subnet_group_name    = aws_db_subnet_group.this.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false
  availability_zone       = var.primary_az
  storage_encrypted       = false
  backup_retention_period = 7

  tags = {
    Name = "${var.name}-primary"
  }
}

provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

resource "aws_db_instance" "read_replica" {
  provider                 = aws.replica
  identifier               = "${var.name}-replica"
  instance_class           = var.instance_class
  publicly_accessible      = false
  replicate_source_db      = aws_db_instance.primary.arn
  skip_final_snapshot      = true
  availability_zone        = var.replica_az
  vpc_security_group_ids   = [aws_security_group.rds_replica.id]
  db_subnet_group_name     = aws_db_subnet_group.replica.name
  depends_on               = [aws_db_instance.primary]

  tags = {
    Name = "${var.name}-read-replica"
  }
}
