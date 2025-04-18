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
  vpc_id      = var.vpc_id

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

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name}-subnet-group"
  }
}

resource "aws_db_instance" "primary" {
  identifier              = "${var.name}-primary"
  allocated_storage       = var.allocated_storage
  storage_type            = "gp3"
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.instance_class
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
  depends_on               = [aws_db_instance.primary]

  tags = {
    Name = "${var.name}-read-replica"
  }
}
