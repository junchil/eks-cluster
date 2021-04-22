# APPNAME is used for the generated executable and as part of the docker image name
APPNAME=rea-web-app
# PREFIX is prepended to the docker image name before NAME
PREFIX=web-kubernetes/
# PROJECT_PKG is the Go import path of the top level of the project
PROJECT_PKG=github.com/junchil/web-kubernetes
# AWS ECR REPO
ECR_REPO_NAME=$(PREFIX)$(APPNAME)
# AWS Region for the ECR
AWS_REGION=ap-southeast-2

COMMIT_HASH ?= $(shell git log --pretty=format:%h -n 1)

ifeq ($(GIT_BRANCH),)
ifneq ($(TRAVIS_PULL_REQUEST_BRANCH),)
GIT_BRANCH = $(TRAVIS_PULL_REQUEST_BRANCH)_PR
endif
endif

ifeq ($(GIT_BRANCH),)
GIT_BRANCH = $(TRAVIS_BRANCH)
endif

ifeq ($(GIT_BRANCH),)
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
endif

GIT_BRANCH_SAFE = $(shell echo "$(GIT_BRANCH)" | tr -cs '[:alnum:].\-\n' '_')
GIT_BRANCH_TAG = $(if $(filter master,$(GIT_BRANCH)),latest,$(GIT_BRANCH_SAFE))

# make sure the ECR repository exists; this needs AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY which will be set in Travis CI
docker-repo:
	if ! aws --region $(AWS_REGION) ecr describe-repositories --repository-names $(ECR_REPO_NAME); then \
		aws --region $(AWS_REGION) ecr create-repository --repository-name $(ECR_REPO_NAME); \
	fi

# AWS ECR docker login for pulling base images and pushing built images.
docker-login: 
	eval $$(aws --region $(AWS_REGION) ecr get-login --no-include-email)

docker-build: docker-login
	@echo "Using AWS ECR uri $(AWS_ECR_REPO_URI)"
	docker build -t $(ECR_REPO_NAME):$(COMMIT_HASH) .
	docker tag $(ECR_REPO_NAME):$(COMMIT_HASH) $(ECR_REPO_NAME):latest

docker-tag: docker-build
	docker tag $(ECR_REPO_NAME):$(COMMIT_HASH) $(AWS_ECR_REPO_URI):$(COMMIT_HASH) && \
	docker tag $(ECR_REPO_NAME):$(COMMIT_HASH) $(AWS_ECR_REPO_URI):$(GIT_BRANCH_TAG)

publish-docker: AWS_ECR_REPO_URI = $$(aws --region=$(AWS_REGION) ecr describe-repositories --repository-names "$(ECR_REPO_NAME)" | jq -r '.repositories[0].repositoryUri')
publish-docker: docker-tag
	docker push $(AWS_ECR_REPO_URI):$(COMMIT_HASH) && \
	docker push $(AWS_ECR_REPO_URI):$(GIT_BRANCH_TAG)

publish: docker-repo publish-docker

check-image-exists:
	@RESULT=$(shell aws ecr describe-images --repository-name $(ECR_REPO_NAME) --region $(AWS_REGION) --image-ids imageTag=$(COMMIT_HASH) | jq '.imageDetails[0].imageTags | index("$(GIT_BRANCH_TAG)-$(COMMIT_HASH)")'); \
	if [ "$$RESULT" = "null" ] || [ -z "$$RESULT" ]; then \
		exit 1; \
	fi