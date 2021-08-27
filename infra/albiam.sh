# AWS_REGION=ap-southeast-2
# CLUSTER_NAME=anycluster
# AWS_ACCOUNT_ID=675617749633
# eksctl utils associate-iam-oidc-provider --region $AWS_REGION --cluster $CLUSTER_NAME --approve
# curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
# aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json

# It will create cfn eksctl-anycluster-addon-iamserviceaccount-default-aws-load-balancer-controller
eksctl create iamserviceaccount --cluster=anycluster --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::675617749633:policy/AWSLoadBalancerControllerIAMPolicy --approve  --override-existing-serviceaccounts