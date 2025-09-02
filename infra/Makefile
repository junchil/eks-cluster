RELEASE_NAME   		= eksapp
CHART_PATH          = eksapp
TF_FOLDER           = terraform/eks
SSH_FOLDER          = terraform/ssh-key
APPS                = terraform kubectl helm aws aws-iam-authenticator eksctl

TF_VERS            ?= 1.5.5
KUBECTL_VERS       ?= 1.28.2
HELM_VERS          ?= 3.15.2
LOCAL_BIN          ?= $(HOME)/bin
CURL               = curl -fSOL
ISTIO_VERSION		= 1.20.0

KUBECONFIG         = $(shell readlink -f kubeconfig.yaml)
KUBECONFIGMAP      = $(shell readlink -f config_map_aws_auth.yaml)
HELM_VALUES        = $(shell readlink -f helm_values.yaml)

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
	curl -Lo aws-iam-authenticator https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.9/aws-iam-authenticator_0.5.9_linux_amd64 && \
	chmod +x aws-iam-authenticator && \
	sudo mv aws-iam-authenticator /usr/local/bin/

depend-eksctl:
	@echo "Installing eksctl"
	$(CURL) https://github.com/weaveworks/eksctl/releases/download/0.62.0/eksctl_Linux_amd64.tar.gz && \
	tar -zxvf eksctl_Linux_amd64.tar.gz && \
	chmod +x eksctl && \
	sudo mv eksctl /usr/local/bin

depend: depend-terraform depend-helm-client depend-aws-iam-authenticator depend-eksctl
	@for bin in $(APPS); do which $$bin; done

copy-ssh-public-key:
	cd $(SSH_FOLDER) && \
	sudo mkdir ~/.ssh && \
	sudo mv stevejc-ec2-test-key-pair.pub ~/.ssh/stevejc-ec2-test-key-pair.pub	

deploy: deploy-terraform deploy-istio-charts deploy-nginx-charts deploy-app-charts

deploy-terraform: copy-ssh-public-key
	@echo Deploying cluster
	cd $(TF_FOLDER) && \
	( \
	$(LOCAL_BIN)/terraform fmt -check && \
	$(LOCAL_BIN)/terraform init && \
	$(LOCAL_BIN)/terraform validate && \
	$(LOCAL_BIN)/terraform plan -out planfile && \
	$(LOCAL_BIN)/terraform apply -parallelism=1 -auto-approve planfile && \
	$(LOCAL_BIN)/terraform output -raw kubeconfig > "$(KUBECONFIG)" && \
	$(LOCAL_BIN)/terraform output -raw config_map_aws_auth > "$(KUBECONFIGMAP)" && \
	$(LOCAL_BIN)/terraform output -raw helm_values > "$(HELM_VALUES)" && \
	echo "Terraform changes are applied successfully" \
	) || exit 1;
	kubectl apply -f $(KUBECONFIGMAP)

deploy-istio-charts:
	@echo Deploying helm charts
	@cd helm && \
	kubectl create namespace istio-system || true && \
	helm repo add istio https://istio-release.storage.googleapis.com/charts && \
	helm dependency update istio && \
	helm upgrade $(RELEASE_NAME)-istio istio --install -f $(HELM_VALUES) -n istio-system && \
	kubectl label namespace default istio-injection=enabled --overwrite && \
	kubectl delete --all pods --namespace=istio-system

deploy-nginx-charts:
	@echo Deploying helm charts
	@cd helm && \
	kubectl create namespace nginx || true && \
	helm dependency update nginx && \
	helm upgrade $(RELEASE_NAME)-nginx nginx --install -f $(HELM_VALUES) -n nginx

#https://github.com/kubernetes-sigs/aws-load-balancer-controller/issues/2551
deploy-app-charts: 
	@echo Deploying helm charts
	@cd helm && \
	helm repo add bitnami https://charts.bitnami.com/bitnami && \
	helm repo add nginx https://kubernetes.github.io/ingress-nginx && \
	helm repo add eks https://aws.github.io/eks-charts && \
	helm dependency update $(CHART_PATH) && \
	kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master" && \
	echo "Deploying eks app chart" && \
	helm upgrade $(RELEASE_NAME) $(CHART_PATH) --install -f $(HELM_VALUES)

deploy-monitoring-chart:
	@echo Deploying helm charts
	@cd helm && \
	kubectl create namespace monitoring || true && \
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && \
	helm dependency update monitoring && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagerconfigs.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_alertmanagers.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_podmonitors.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_probes.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusagents.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_prometheusrules.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_scrapeconfigs.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml && \
	kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.69.1/example/prometheus-operator-crd/monitoring.coreos.com_thanosrulers.yaml && \
	helm upgrade $(RELEASE_NAME)-monitoring monitoring --install -f $(HELM_VALUES) -n monitoring

deploy-karpenter-crd-chart:
	@echo Deploying helm charts
	@cd helm && \
	kubectl create namespace karpenter || true && \
	helm upgrade  $(RELEASE_NAME)-karpenter-crd karpenter-crd --install -f $(HELM_VALUES) -n karpenter

deploy-karpenter-chart:
	@echo Deploying helm charts
	@cd helm && \
	kubectl create namespace karpenter || true && \
	helm upgrade  $(RELEASE_NAME)-karpenter karpenter --install -f $(HELM_VALUES) -n karpenter

deploy-kube-dashboard:
	@echo Deploying cluster dashboard
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.5/aio/deploy/recommended.yaml
	kubectl apply -f eks-admin-service-account.yaml

deploy-kube-metrics-server:
	@echo Deploying cluster metrics server
	kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

destroy-iam-serviceaccount-aws-alb: 
	eksctl delete iamserviceaccount --cluster=anycluster --name=aws-load-balancer-controller
	
destroy-charts: destroy-iam-serviceaccount-aws-alb
	helm uninstall $(RELEASE_NAME)-monitoring -n monitoring || true && \
	helm uninstall $(RELEASE_NAME)-karpenter -n karpenter || true && \
	helm uninstall $(RELEASE_NAME)-karpenter-crd -n karpenter || true && \
	helm uninstall $(RELEASE_NAME) || true && \
	helm uninstall $(RELEASE_NAME)-nginx -n nginx || true && \
	helm uninstall $(RELEASE_NAME)-istio -n istio-system || true && \
	echo "Helm changes are destroyed successfully"

destroy-terraform:
	@echo Destroying all resources created by terraform
	cd $(TF_FOLDER) && \
	( \
		$(LOCAL_BIN)/terraform init && \
		$(LOCAL_BIN)/terraform destroy -auto-approve || true && \
		echo "Terraform changes are destroyed successfully" \
	)

destroy: deploy-terraform destroy-charts destroy-terraform