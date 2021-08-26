AWS_REGION=ap-southeast-2
CLUSTER_NAME=anycluster
AWS_ACCOUNT_ID=675617749633
eksctl utils associate-iam-oidc-provider --region $AWS_REGION --cluster $CLUSTER_NAME --approve
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam-policy.json
eksctl create iamserviceaccount --cluster=$CLUSTER_NAME --name=aws-load-balancer-controller --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy --approve  --override-existing-serviceaccounts