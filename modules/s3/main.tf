terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}


# SOURCE BUCKET IN PRIMARY REGION
resource "aws_s3_bucket" "source" {
  bucket = "${var.bucket_prefix}-source"
  force_destroy = true
  tags = {
    Name = "${var.bucket_prefix}-source"
  }
}

# DESTINATION BUCKET IN SECONDARY REGION
provider "aws" {
  alias  = "replica"
  region = var.replica_region
}

resource "aws_s3_bucket" "destination" {
  provider = aws.replica
  bucket   = "${var.bucket_prefix}-replica"
  force_destroy = true
  tags = {
    Name = "${var.bucket_prefix}-replica"
  }
}

# IAM ROLE FOR REPLICATION
resource "aws_iam_role" "replication_role" {
  name = "${var.bucket_prefix}-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "replication_policy" {
  name = "${var.bucket_prefix}-replication-policy"
  role = aws_iam_role.replication_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.source.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl"
        ]
        Resource = ["${aws_s3_bucket.source.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = ["${aws_s3_bucket.destination.arn}/*"]
      }
    ]
  })
}

# ENABLE VERSIONING ON BOTH BUCKETS
resource "aws_s3_bucket_versioning" "source_versioning" {
  bucket = aws_s3_bucket.source.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "destination_versioning" {
  provider = aws.replica
  bucket   = aws_s3_bucket.destination.id

  versioning_configuration {
    status = "Enabled"
  }
}

# REPLICATION CONFIGURATION
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.source_versioning]

  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    delete_marker_replication {
      status = "Enabled"
    }

    filter {}

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}


# IAM POLICY FOR PUBLIC READ ACCESS ON 'uploads' FOLDER IN BOTH BUCKETS
resource "aws_s3_bucket_policy" "source_public_read" {
  bucket = aws_s3_bucket.source.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "PublicReadUploads",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "arn:aws:s3:::${aws_s3_bucket.source.bucket}/uploads/*"
      }
    ]
  })
}

resource "aws_s3_bucket_policy" "destination_public_read" {
  bucket = aws_s3_bucket.destination.id
  provider = aws.replica

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "PublicReadUploads",
        Effect: "Allow",
        Principal: "*",
        Action: "s3:GetObject",
        Resource: "arn:aws:s3:::${aws_s3_bucket.destination.bucket}/uploads/*"
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "source_block" {
  bucket = aws_s3_bucket.source.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}


resource "aws_s3_bucket_public_access_block" "destination_block" {
  provider = aws.replica
  bucket   = aws_s3_bucket.destination.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}