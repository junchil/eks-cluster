#EKS Service
resource "aws_eks_cluster" "eks-cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster_role.arn
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