terraform {
  backend "s3" {
    bucket         = "terraform-up-and-running-state-eks"
    key            = "cluster/ap-southeast-2/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-up-and-running-locks-eks"
    encrypt        = true
  }
}

module "vpc" {
  source              = "./vpc"
  cidr                = "10.0.0.0/16"
  vpc_name            = var.vpc_name
  cluster_name        = var.cluster_name
  public_subnet_cidr  = ["10.0.204.0/22", "10.0.208.0/22", "10.0.212.0/22"]
  private_subnet_cidr = ["10.0.228.0/22", "10.0.232.0/22", "10.0.236.0/22"]
}

module "bastion-host" {
  count                   = var.bastion_enable ? 1 : 0
  source                  = "./bastion-host"
  instance_type           = var.instance_type
  instance_ami            = var.instance_ami
  server_name             = var.server_name
  aws_key_pair_name       = var.aws_key_pair_name
  aws_key_pair_public_key = var.aws_key_pair_public_key
  vpc_id                  = module.vpc.vpc_id
  k8-subnet               = module.vpc.public_subnet[0]
}

module "eks" {
  source       = "./cluster"
  vpc_id       = module.vpc.vpc_id
  cluster_name = var.cluster_name
  #kubernetes_server_instance_sg = module.bastion-host.kubernetes_server_instance_sg
  eks_subnets           = flatten([module.vpc.public_subnet])
  worker_subnet         = flatten([module.vpc.private_subnet])
  subnet_ids            = flatten([module.vpc.public_subnet, module.vpc.private_subnet])
  kubernetes_namespace  = "fargate"
  kubernetes_labels     = {}
  oidc_provider_enabled = true
}

resource "aws_acm_certificate" "cert" {
  // has to be a wildcard all of the subdomains should be certified
  domain_name       = "*.${var.ingress_url}"
  validation_method = "DNS"

  tags = {
    Name = var.cluster_name
  }

  lifecycle {
    create_before_destroy = true
  }
}