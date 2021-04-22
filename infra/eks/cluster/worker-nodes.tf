#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EC2 Security Group to allow networking traffic
#  * Data source to fetch latest EKS worker AMI
#  * AutoScaling Launch Configuration to configure worker instances
#  * AutoScaling Group to launch worker instances
#

#IAM Role
resource "aws_iam_role" "worker-node-role" {
  name = "${local.name_prefix}-worker-nodes-role"

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

  tags = local.common_tags

}

data "aws_iam_policy_document" "worker-node-policy" {
  # Source: https://raw.githubusercontent.com/kubernetes-sigs/aws-alb-ingress-controller/v1.1.2/docs/examples/iam-policy.json
  statement {
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "tag:GetResources",
      "tag:TagResources",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    actions = [
      "waf:GetWebACL",
    ]

    resources = [
      "*",
    ]
  }

  # worker node Route 53 policy
  statement {
    actions = [
      "route53:GetChange",
    ]

    resources = [
      "arn:aws:route53:::change/*",
    ]
  }

  statement {
    actions = [
      "route53:ChangeResourceRecordSets",
    ]

    resources = [
      "arn:aws:route53:::hostedzone/*",
    ]
  }

  statement {
    actions = [
      "route53:ListHostedZones",
      "route53:ListHostedZonesByName",
      "route53:ListResourceRecordSets",
    ]

    resources = [
      "*",
    ]
  }

  # worker node autoscaling policy
  statement {
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "worker-node-policy" {
  name        = "${local.name_prefix}-worker-node-policy"
  description = "Allow EKS worker nodes to use various AWS APIs"
  policy      = data.aws_iam_policy_document.worker-node-policy.json
}

resource "aws_iam_role_policy_attachment" "worker-node-policy" {
  role       = aws_iam_role.worker-node-role.name
  policy_arn = aws_iam_policy.worker-node-policy.arn
}

resource "aws_iam_policy" "eks-tagging" {
  name        = "production_resource_tagging_for_eks"
  path        = "/"
  description = "resource_tagging_for_eks"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "tag:GetResources",
                "tag:UntagResources",
                "tag:GetTagValues",
                "tag:GetTagKeys",
                "tag:TagResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-AmazonEC2FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.worker-node-role.name
}

resource "aws_iam_role_policy_attachment" "worker-node-resource_tagging_for_eks" {
  policy_arn = aws_iam_policy.eks-tagging.arn
  role       = aws_iam_role.worker-node-role.name
}

resource "aws_iam_instance_profile" "worker-node" {
  name = "${local.name_prefix}-eks-worker-node-profile"
  role = aws_iam_role.worker-node-role.name
}

#Security Group
resource "aws_security_group" "worker-node-sg" {
  name        = "${local.name_prefix}-worker-nodeSG"
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

resource "aws_security_group_rule" "worker-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker-node-sg.id
  source_security_group_id = aws_security_group.worker-node-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker-node-sg.id
  source_security_group_id = aws_security_group.cluster-sg.id
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-node-for-control-server" {
  description              = "Allow worker Kubelets and pods to receive communication from the control server"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker-node-sg.id
  source_security_group_id = var.kubernetes-server-instance-sg
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-node-for-alb" {
  description              = "Allow worker Kubelets and pods to receive communication from alb"
  from_port                = 0
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker-node-sg.id
  source_security_group_id = aws_security_group.eks_alb_sg.id
  to_port                  = 65535
  type                     = "ingress"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.eks-cluster.version}-v*"]
  }

  most_recent = true
  owners      = ["amazon"]
}

# EKS currently documents this required userdata for EKS worker nodes to
# properly configure Kubernetes applications on the EC2 instance.
# We utilize a Terraform local here to simplify Base64 encoding this
# information into the AutoScaling Launch Configuration.
# More information: https://docs.aws.amazon.com/eks/latest/userguide/launch-workers.html

locals {
  worker-node-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority[0].data}' '${var.cluster-name}'
USERDATA

}

#Launch Configuration
resource "aws_launch_template" "worker" {
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker-node-sg.id]
    delete_on_termination       = true
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.worker-node.name
  }

  image_id      = data.aws_ami.eks-worker.id
  instance_type = var.worker_node_instance_type
  name_prefix   = local.name_prefix
  user_data     = base64encode(local.worker-node-userdata)

  lifecycle {
    create_before_destroy = true
  }

  tags = local.common_tags
}

#Autoscalling Group
resource "aws_autoscaling_group" "worker" {
  max_size            = var.worker_node_count_max
  min_size            = var.worker_node_count_min
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = var.worker_subnet

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${aws_eks_cluster.eks-cluster.name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = var.worker_node_autoscaling ? "kubernetes.io/cluster-autoscaler/enabled" : "kubernetes.io/cluster-autoscaler/disabled"
    value               = "true"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = local.common_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = var.worker_node_on_demand_base_capacity
      on_demand_percentage_above_base_capacity = var.worker_node_on_demand_percentage_above_base_capacity
      spot_allocation_strategy                 = var.worker_node_spot_allocation_strategy
    }
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.worker.id
        version            = "$Latest"
      }

      dynamic "override" {
        for_each = var.worker_node_instance_type_override
        content {
          instance_type     = override.value["instance_type"]
          weighted_capacity = override.value["weight"]
        }
      }
    }
  }
}

