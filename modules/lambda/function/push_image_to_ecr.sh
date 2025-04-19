#!/bin/bash

REPO_NAME="lambda-failover"
IMAGE_TAG="latest"
AWS_REGION="eu-west-2"

# Login & build
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.$AWS_REGION.amazonaws.com
docker build -t $REPO_NAME lambda/

# Tag & push
docker tag $REPO_NAME:latest <your-account-id>.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
docker push <your-account-id>.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG
