RELEASE_NAME             = eksapp
CHART_PATH               = eks-app
TF_FOLDER            	 = terraform/eks
SSH_FOLDER               = terraform/ssh-key
APPS                 	 = terraform kubectl helm aws aws-iam-authenticator eksctl

TF_VERS                 	?= 0.15.3
KUBECTL_VERS            	?= 1.16.0
HELM_VERS               	?= 3.6.0
LOCAL_BIN               	?= $(HOME)/bin
CURL                     	= curl -fSOL

KUBECONFIG           = $(shell readlink -f kubeconfig.yaml)
KUBECONFIGMAP        = $(shell readlink -f config_map_aws_auth.yaml)
HELM_VALUES          = $(shell readlink -f helm_values.$(ENVIRONMENT_NAME).yaml)

# export as env-variable
export KUBECONFIG

depend-terraform:
	@echo "Installing terraform"
	@if terraform version > /dev/null && [ "`terraform version | head -1`" = "Terraform v$(TF_VERS)" ]; \
		then echo "Using installed terraform v$(TF_VERS)"; \
		else \
			$(CURL) "https://releases.hashicorp.com/terraform/$(TF_VERS)/terraform_$(TF_VERS)_linux_amd64.zip" && \
			unzip -ou "terraform_$(TF_VERS)_linux_amd64.zip" -d "$(LOCAL_BIN)" && \
			rm -f "terraform_$(TF_VERS)_linux_amd64.zip"; \
		fi

depend-kubernetes-client:
	@echo "Installing kubernetes-client"
	$(CURL) https://storage.googleapis.com/kubernetes-release/release/v$(KUBECTL_VERS)/bin/linux/amd64/kubectl && \
	install ./kubectl $(LOCAL_BIN) && \
	rm -f ./kubectl

depend-helm-client: depend-kubernetes-client
	@echo "Installing helm-client"
	curl -fSL https://get.helm.sh/helm-v${HELM_VERS}-linux-amd64.tar.gz -o helm-linux-amd64.tar.gz && \
	tar -zxvf helm-linux-amd64.tar.gz && \
	install linux-amd64/helm $(LOCAL_BIN) && \
	rm -rf "helm-v${HELM_VERS}-linux-amd64.tar.gz" linux-amd64

depend-aws-iam-authenticator:
	@echo "Installing aws-iam-authenticator"
	$(CURL) https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/aws-iam-authenticator && \
	chmod +x aws-iam-authenticator && \
	sudo mv aws-iam-authenticator /usr/local/bin/

depend-eksctl:
	@echo "Installing eksctl"
	curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
	sudo mv /tmp/eksctl /usr/local/bin


depend: depend-terraform depend-helm-client depend-aws-iam-authenticator depend-eksctl
	@for bin in $(APPS); do which $$bin; done

copy-ssh-public-key:
	cd $(SSH_FOLDER) && \
	sudo mkdir ~/.ssh && \
	sudo mv stevejc-ec2-test-key-pair.pub ~/.ssh/stevejc-ec2-test-key-pair.pub	

deploy-terraform: copy-ssh-public-key
	@echo Deploying cluster
	cd $(TF_FOLDER) && \
	( \
	terraform fmt -check && \
	terraform init && \
	terraform validate && \
	terraform plan && \
	terraform apply -auto-approve && \
	terraform output -raw kubeconfig > "$(KUBECONFIG)" && \
	terraform output -raw config_map_aws_auth > "$(KUBECONFIGMAP)" && \
	terraform output -raw helm_values > "$(HELM_VALUES)" && \
	echo "Terraform changes are applied successfully" \
	) || exit 1;
	kubectl apply -f $(KUBECONFIGMAP)

deploy-helm-charts:
	@echo Deploying helm charts
	@cd helm && \
	helm repo add bitnami https://charts.bitnami.com/bitnami && \
	helm repo add stable https://charts.helm.sh/stable && \
	helm repo add common https://charts.helm.sh/incubator && \
	helm repo add eks https://aws.github.io/eks-charts && \
	helm dependency update $(CHART_PATH) && \
	echo "Deploying rea app chart" && \
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) --install -f $(HELM_VALUES)

deploy-kube-dashboard:
	@echo Deploying cluster dashboard
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.5/aio/deploy/recommended.yaml
	kubectl apply -f eks-admin-service-account.yaml
	
deploy: deploy-terraform deploy-helm-charts deploy-kube-dashboard

destroy-helm-charts:
	helm uninstall $(RELEASE_NAME) && \
	echo "Helm changes are destroyed successfully"

destroy-terraform:
	@echo Destroying all resources created by terraform
	cd $(TF_FOLDER) && \
	( \
		terraform init && \
		terraform destroy -auto-approve && \
		echo "Terraform changes are destroyed successfully" \
	)

destroy: deploy-terraform destroy-helm-charts destroy-terraform