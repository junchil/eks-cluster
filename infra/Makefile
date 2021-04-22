RELEASE_NAME             = servian
CHART_PATH               = rea-web
TF_FOLDER            	 = eks
APPS                 	 = terraform kubectl helm aws aws-iam-authenticator

TF_VERS                 	?= 0.12.24
KUBECTL_VERS            	?= 1.16.0
HELM_VERS               	?= 3.2.4
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
	$(CURL) https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator && \
	install ./aws-iam-authenticator $(LOCAL_BIN) && \
	rm -f ./aws-iam-authenticator

depend: depend-terraform depend-helm-client depend-aws-iam-authenticator
	@for bin in $(APPS); do which $$bin; done

deploy-terraform:
	@echo Deploying cluster
	cd $(TF_FOLDER) && \
	( \
	terraform init && \
	terraform plan && \
	terraform apply -auto-approve && \
	terraform output kubeconfig > "$(KUBECONFIG)" && \
	terraform output config_map_aws_auth > "$(KUBECONFIGMAP)" && \
	terraform output helm_values > "$(HELM_VALUES)" && \
	echo "Terraform changes are applied successfully" \
	) || exit 1;
	kubectl apply -f $(KUBECONFIGMAP)

deploy-charts:
	@echo Deploying charts
	@cd charts && \
	helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator && \
	helm dependency update $(CHART_PATH) && \
	echo "Deploying rea app chart" && \
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) --install -f $(HELM_VALUES)

deploy: deploy-terraform deploy-charts

destroy-charts:
	helm uninstall $(RELEASE_NAME) && \
	echo "Helm changes are destroyed successfully"

destroy-terraform:
	@echo Destroying all resources created by terraform
	cd $(TF_FOLDER) && \
	( \
		terraform init && \
		terraform destroy -auto-approve -force && \
		echo "Terraform changes are destroyed successfully" \
	)

destroy: deploy-terraform destroy-charts destroy-terraform