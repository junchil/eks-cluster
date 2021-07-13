#https://docs.aws.amazon.com/eks/latest/userguide/sec-group-reqs.html#cluster-sg
# Cluster security Group
resource "aws_security_group" "cluster_sg" {
  name        = "${local.name_prefix}-cluster-sg"
  description = "Cluster control plane communication with worker nodes"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
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

resource "aws_security_group_rule" "cluster_ingress_node_https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.worker_node_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_node_api" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster_sg.id
  source_security_group_id = aws_security_group.worker_node_sg.id
  type                     = "ingress"
}

#Worker node security Group
resource "aws_security_group" "worker_node_sg" {
  name        = "${local.name_prefix}-worker-node-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      "Name"                                        = "${local.name_prefix}-worker-node"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "worker_node_ingress_self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.worker_node_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_node_ingress_cluster_https" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.cluster_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_node_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.cluster_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker_node_for_alb" {
  description              = "Allow worker Kubelets and pods to receive communication from alb"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.eks_alb_sg.id
  type                     = "ingress"
}

# resource "aws_security_group_rule" "worker_node_for_control_server" {
#   description              = "Allow worker Kubelets and pods to receive communication from the bastion host"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.worker_node_sg.id
#   source_security_group_id = var.kubernetes_server_instance_sg
#   type                     = "ingress"
# }