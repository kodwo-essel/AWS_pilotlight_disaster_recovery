#!/bin/bash

set -e

# Enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Fetch environment variables from SSM Parameter Store
# Specify the region dynamically (you can adjust this to your needs)
export AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)

export ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --region $AWS_REGION)

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

# Fetch parameters using the dynamic region
export S3_BUCKET_REGION=$(aws ssm get-parameter --name "/${ecr_name}-backend/S3_BUCKET_REGION" --query "Parameter.Value" --output text --region $AWS_REGION)
export S3_BUCKET_NAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/S3_BUCKET_NAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_HOST=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_HOST" --query "Parameter.Value" --output text --region $AWS_REGION | sed 's/:.*//')
export DB_PORT=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_PORT" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_NAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_NAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_USERNAME=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_USERNAME" --query "Parameter.Value" --output text --region $AWS_REGION)
export DB_PASSWORD=$(aws ssm get-parameter --name "/${ecr_name}-backend/DB_PASSWORD" --with-decryption --query "Parameter.Value" --output text --region $AWS_REGION)

echo "AWS_REGION=$AWS_REGION" >> /home/ec2-user/.env
echo "S3_BUCKET_REGION=$S3_BUCKET_REGION" >> /home/ec2-user/.env
echo "S3_BUCKET_NAME=$S3_BUCKET_NAME" >> /home/ec2-user/.env
echo "DB_HOST=$DB_HOST" >> /home/ec2-user/.env
echo "DB_PORT=$DB_PORT" >> /home/ec2-user/.env
echo "DB_NAME=$DB_NAME" >> /home/ec2-user/.env
echo "DB_USERNAME=$DB_USERNAME" >> /home/ec2-user/.env
echo "DB_PASSWORD=$DB_PASSWORD" >> /home/ec2-user/.env

echo "VITE_PUBLIC_API_URL=http://backend:8080/api" >> /home/ec2-user/.env


# Pull Docker image passed via environment variable
export FRONTEND_IMAGE_URI="${FRONTEND_IMAGE_URI}"  # This will be templated via Terraform
export BACKEND_IMAGE_URI="${BACKEND_IMAGE_URI}"  # This will be templated via Terraform
export ecr_name="${ecr_name}"  # This will be templated via Terraform

echo "ecr_name=$ecr_name" >> /home/ec2-user/others.env
echo "FRONTEND_IMAGE_URI=$FRONTEND_IMAGE_URI" >> /home/ec2-user/.env
echo "BACKEND_IMAGE_URI=$BACKEND_IMAGE_URI" >> /home/ec2-user/.env

sudo docker pull $FRONTEND_IMAGE_URI
sudo docker pull $BACKEND_IMAGE_URI

# Download docker-compose.yml from S3
S3_BUCKET_NAME="${S3_BUCKET_NAME}"
PATH_TO_DOCKER_COMPOSE="${PATH_TO_DOCKER_COMPOSE}"
aws s3 cp s3://${S3_BUCKET_NAME}/${PATH_TO_DOCKER_COMPOSE} /home/ec2-user/docker-compose.yml

# Run Docker Compose
cd /home/ec2-user
docker-compose up -d
