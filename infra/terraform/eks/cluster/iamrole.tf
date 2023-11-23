# #EKS Worker Node IAM Role
# resource "aws_iam_role" "worker_node_role" {
#   name = "${local.name_prefix}-worker-nodes-role"

#   assume_role_policy = <<POLICY
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Effect": "Allow",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Action": "sts:AssumeRole"
#     }
#   ]
# }
# POLICY

#   tags = local.common_tags

# }

# resource "aws_iam_role_policy_attachment" "worker_node_policy" {
#   role       = aws_iam_role.worker_node_role.name
#   policy_arn = aws_iam_policy.worker_node_policy.arn
# }

#EKS Karpenter Node IAM Role
resource "aws_iam_role" "karpenter_node_role" {
  name = "${var.cluster_name}-karpenter-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "karpenter-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter-node-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonS3FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-resource_tagging_for_eks" {
  policy_arn = aws_iam_policy.eks-tagging.arn
  role       = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_instance_profile" "worker-node" {
  name = "${local.name_prefix}-eks-worker-node-profile"
  role = aws_iam_role.karpenter_node_role.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policy" {
  role       = aws_iam_role.karpenter_node_role.name
  policy_arn = aws_iam_policy.worker_node_policy.arn
}

resource "aws_iam_role" "karpenter_controller_role" {
  name               = "${var.cluster_name}-karpenter-controller-role"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume_role.json
}

# resource "aws_iam_role_policy_attachment" "worker-node-AmazonSSMManagedInstanceCore" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = aws_iam_role.worker_node_role.name
# }

# resource "aws_iam_role_policy_attachment" "worker-node-AmazonEKSWorkerNodePolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
#   role       = aws_iam_role.worker_node_role.name
# }

# resource "aws_iam_role_policy_attachment" "worker-node-AmazonEKS_CNI_Policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
#   role       = aws_iam_role.worker_node_role.name
# }

# resource "aws_iam_role_policy_attachment" "worker-node-AmazonEC2ContainerRegistryReadOnly" {
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
#   role       = aws_iam_role.worker_node_role.name
# }



#EKS ClusterIAM Role
resource "aws_iam_role" "cluster_role" {
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
  role       = aws_iam_role.cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.cluster_role.name
}