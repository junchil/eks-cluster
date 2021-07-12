#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

#IAM Role
resource "aws_iam_role" "cluster-role" {
  name = "${local.name_prefix}-cluster-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster-role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster-role.name
}

#Security Group
resource "aws_security_group" "cluster_sg" {
  name        = "${local.name_prefix}-clusterSG"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-cluster_sg"
    },
  )
}

resource "aws_security_group_rule" "cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.worker-node-sg.id
  to_port                  = 443
  type                     = "ingress"
}

# resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
#   cidr_blocks       = ["0.0.0.0/0"]
#   description       = "Allow workstation to communicate with the cluster API Server"
#   from_port         = 443
#   protocol          = "tcp"
#   security_group_id = aws_security_group.cluster_sg.id
#   to_port           = 443
#   type              = "ingress"
# }

#EKS Service
resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster-role.arn
  version  = var.cluster_version

  vpc_config {
    security_group_ids = [aws_security_group.cluster_sg.id]
    # https://docs.aws.amazon.com/eks/latest/userguide/network_reqs.html
    subnet_ids = var.subnet_ids
  }

  tags = merge(
    local.common_tags,
    {
      "Name" = "${local.name_prefix}-eks"
    },
  )

  depends_on = [
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy,
  ]
}

# # Create an admin role and let everyone in the account assume it to maintain the eks cluster
# resource "aws_iam_role" "admin-role" {
#   name = "${local.name_prefix}-kube-cluster-admin-role"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "AWS": "${var.everyone_admin ? "arn:aws:iam::${local.account_id}:root" : local.caller_arn}"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY

#   tags = local.common_tags

# }

# resource "aws_iam_role_policy_attachment" "admin-AmazonEKSClusterPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
#   role       = aws_iam_role.admin-role.name
# }

# resource "aws_iam_role_policy_attachment" "admin-AmazonEKSServicePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
#   role       = aws_iam_role.admin-role.name
# }

# Enabling IAM Roles for Service Accounts in Kubernetes cluster
#
# From official docs:
# The IAM roles for service accounts feature is available on new Amazon EKS Kubernetes version 1.14 clusters,
# and clusters that were updated to versions 1.14 or 1.13 on or after September 3rd, 2019.
#
# https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
# https://medium.com/@marcincuber/amazon-eks-with-oidc-provider-iam-roles-for-kubernetes-services-accounts-59015d15cb0c
#

data "tls_certificate" "cluster" {
  count = var.oidc_provider_enabled ? 1 : 0
  url   = join("", aws_eks_cluster.eks-cluster.*.identity.0.oidc.0.issuer)
}

resource "aws_iam_openid_connect_provider" "default" {
  count = var.oidc_provider_enabled ? 1 : 0
  url   = join("", aws_eks_cluster.eks-cluster.*.identity.0.oidc.0.issuer)
  tags  = local.common_tags

  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [join("", data.tls_certificate.cluster.*.certificates.0.sha1_fingerprint)]
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [
    aws_eks_cluster.eks-cluster
  ]

  provisioner "local-exec" {
    command = var.wait_for_cluster_cmd
    environment = {
      ENDPOINT = aws_eks_cluster.eks-cluster.endpoint
    }
  }
}