#!/bin/sh
# NAME is used for the generated executable and as part of the docker image name
NAME=goprometheus
APPNAME=goprometheus
# PREFIX is prepended to the docker image name before NAME
PREFIX=eks-cluster/
# PROJECT_PKG is the Go import path of the top level of the project
PROJECT_PKG=github.com/junchil/eks-cluster
# AWS ECR REPO
ECR_REPO_NAME=$PREFIX$APPNAME
# AWS Region for the ECR
AWS_REGION=ap-southeast-2
# Commit hash for the service
COMMIT_HASH=$(git log --pretty=format:%h -n 1 -- .)
echo "Commit hash: $COMMIT_HASH"
# Check ecr repo exists or not
if ! aws --region $AWS_REGION ecr describe-repositories --repository-names $ECR_REPO_NAME; then 
	aws --region $AWS_REGION ecr create-repository --repository-name $ECR_REPO_NAME;
    aws --region $AWS_REGION ecr put-lifecycle-policy --repository-name $ECR_REPO_NAME --lifecycle-policy-text file://ecr-lifecycle-policy.json;
fi
# ECR login
#aws ecr get-login-password --region $AWS_REGION
AWS_ECR_REPO_URI=$(aws --region=$AWS_REGION ecr describe-repositories --repository-names "$ECR_REPO_NAME" | jq -r '.repositories[0].repositoryUri')
echo "Using AWS ECR uri $AWS_ECR_REPO_URI"
# Check image exists or not
RESULT=$(aws ecr describe-images --repository-name $ECR_REPO_NAME --region $AWS_REGION --image-ids imageTag=$COMMIT_HASH | jq '.imageDetails[0].imageTags')
if [ "$RESULT" = "null" ] || [ -z "$RESULT" ]; then 
    docker build -t $ECR_REPO_NAME:$COMMIT_HASH .
    docker tag $ECR_REPO_NAME:$COMMIT_HASH $AWS_ECR_REPO_URI:latest
    docker tag $ECR_REPO_NAME:$COMMIT_HASH $AWS_ECR_REPO_URI:$COMMIT_HASH
    docker push $AWS_ECR_REPO_URI:$COMMIT_HASH
    docker push $AWS_ECR_REPO_URI:latest
fi