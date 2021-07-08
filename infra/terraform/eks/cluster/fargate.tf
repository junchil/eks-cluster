data "aws_iam_policy_document" "assume_role" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks-fargate-pods.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this_fargate" {
  name               = "${var.cluster_name}-fargate-${var.kubernetes_namespace}"
  assume_role_policy = join("", data.aws_iam_policy_document.assume_role.*.json)
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "amazon_eks_fargate_pod_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = join("", aws_iam_role.this_fargate.*.name)
}

resource "aws_eks_fargate_profile" "this_fargate" {
  cluster_name           = var.cluster_name
  fargate_profile_name   = "${var.kubernetes_namespace}-fargate-profile"
  pod_execution_role_arn = join("", aws_iam_role.this_fargate.*.arn)
  subnet_ids             = var.worker_subnet
  tags                   = local.common_tags

  selector {
    namespace = var.kubernetes_namespace
    labels    = var.kubernetes_labels
  }

  depends_on = [
    null_resource.wait_for_cluster
  ]
}