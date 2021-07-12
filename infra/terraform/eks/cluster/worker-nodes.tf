#Security Group
resource "aws_security_group" "worker_node_sg" {
  name        = "${local.name_prefix}-worker-nodeSG"
  description = "Security group for all nodes in the cluster"
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
      "Name"                                        = "${local.name_prefix}-worker-node"
      "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    },
  )
}

resource "aws_security_group_rule" "worker-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.worker_node_sg.id
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.cluster_sg.id
  type                     = "ingress"
}

# resource "aws_security_group_rule" "worker-node-for-control-server" {
#   description              = "Allow worker Kubelets and pods to receive communication from the control server"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.worker_node_sg.id
#   source_security_group_id = var.kubernetes_server_instance_sg
#   type                     = "ingress"
# }

resource "aws_security_group_rule" "worker-node-for-alb" {
  description              = "Allow worker Kubelets and pods to receive communication from alb"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_node_sg.id
  source_security_group_id = aws_security_group.eks_alb_sg.id
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
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.eks-cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.eks-cluster.certificate_authority[0].data}' '${var.cluster_name}'
USERDATA

}

#Launch Configuration
resource "aws_launch_template" "worker" {
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.worker_node_sg.id]
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

