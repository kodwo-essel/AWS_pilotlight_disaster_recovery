#!/bin/bash

set -e

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Install aws cli
sudo apt-get install -y awscli

# Fetch environment variables from SSM Parameter Store
# Specify the region dynamically (you can adjust this to your needs)
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

# Fetch parameters using the dynamic region
export S3_BUCKET_REGION=$(aws ssm get-parameter --name "/${ecr_name}-backend/S3_BUCKET_REGION" --query "Parameter.Value" --output text --region $AWS_REGION)
export S3_BUCKET_NAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/S3_BUCKET_NAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_HOST=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_HOST" --query "Parameter.Value" --output text --region $AWS_REGION | sed 's/:.*//')
export DB_PORT=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_PORT" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_NAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_NAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_USERNAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_USERNAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_PASSWORD=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_PASSWORD" --with-decryption --query "Parameter.Value" --output text --region $AWS_REGION)



# Pull Docker image passed via environment variable
FRONTEND_IMAGE_URI="${FRONTEND_IMAGE_URI}"  # This will be templated via Terraform
BACKEND_IMAGE_URI="${BACKEND_IMAGE_URI}"  # This will be templated via Terraform
docker pull $FRONTEND_IMAGE_URI
docker pull $BACKEND_IMAGE_URI


# Download docker-compose.yml from S3
S3_BUCKET_NAME="${S3_BUCKET_NAME}"
PATH_TO_DOCKER_COMPOSE="${PATH_TO_DOCKER_COMPOSE}"
aws s3 cp s3://${S3_BUCKET_NAME}/${PATH_TO_DOCKER_COMPOSE} /home/ubuntu/docker-compose.yml

# Run Docker Compose
cd /home/ubuntu
docker compose up -d
