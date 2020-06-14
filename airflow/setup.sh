#!/bin/sh

LOG="airflow-deploy.log"
DATE=$(date '+%Y-%m-%d_%H%M%S')

if [ $# -ne 1 ]; then
    echo "Incorrect parameters. Please provide project name."
    echo "sh ./steup.sh <PROJECT_NAME>"
    exit 1
fi

if [ -z "$AWS_REGION" ]; then
    echo "Please set AWS_REGION environment variable."
    exit 1
fi

if [ -z "$AWS_PROFILE" ]; then
    echo "Please set AWS_PROFILE environment variable."
    exit 1
else
    echo "Project Name: $1"
    echo "AWS Profile: ${AWS_PROFILE}"
fi

echo "Starting Airflow image deployment at "$DATE | tee -a $LOG

REPOSITORY_NAME="$1_repository"
echo "aws ecr create-repository --repository-name $REPOSITORY_NAME --image-tag-mutability IMMUTABLE" | tee -a $LOG

output=$(aws ecr create-repository --repository-name $REPOSITORY_NAME --image-tag-mutability IMMUTABLE | tee -a $LOG)

if  [ -z "$output" ]; then
    echo "Failed to create ECR repository" | tee -a $LOG
    exit 1
else
    echo "Repository $REPOSITORY_NAME created successfuly!" | tee -a $LOG
fi

REGISTRY_URI=$(echo $output | jq '.repository.repositoryUri' | tr -d \")
PASSWORD_STDIN=$(echo $REGISTRY_URI | awk '{split($0, a, "/"); print a[1]'})
# echo $REGISTRY_URI 
# echo $PASSWORD_STDIN

echo "Login aws ecr..."
echo "aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $PASSWORD_STDIN" | tee -a $LOG
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $PASSWORD_STDIN
if [ $? -ne 0 ]; then
    echo "Failed to login ECR repository!" | tee -a $LOG
    exit 1
else
    echo "Login done!" | tee -a $LOG
fi

echo "Executing docker build..."
docker build -t $REPOSITORY_NAME . | tee -a $LOG
docker build -t $REPOSITORY_NAME .
if [ $? -ne 0 ]; then
    echo "Failed to build Docker image" | tee -a $LOG
    exit 1
else
    echo "Docker build done!" | tee -a $LOG
fi

echo "Tagging Docker image..."
TAG=$REGISTRY_URI:latest
docker tag $REPOSITORY_NAME:latest $TAG | tee -a $LOG
if [ $? -ne 0 ]; then
    echo "Failed to tag Docker image" | tee -a $LOG
    exit 1
else
    echo "Docker tag done!" | tee -a $LOG
fi

echo "Pushing image to ECR..."
docker push $TAG | tee -a $LOG
if [ $? -ne 0 ]; then
    echo "Failed to push Docker image" | tee -a $LOG
    exit 1
else
    echo "Docker image push done!" | tee -a $LOG
fi

DATE=$(date '+%Y-%m-%d_%H%M%S')
echo "Finished Airflow image deployment at "$DATE | tee -a $LOG