terraform {
  backend "s3" {
    bucket = "terraform-up-and-running-state-eks"
    key    = "cluster/ap-southeast-2/terraform.tfstate"
    region = "ap-southeast-1"
    dynamodb_table = "terraform-up-and-running-locks-eks"
    encrypt        = true
  }
}

module "vpc" {
  source              = "./vpc"
  cidr                = "10.0.0.0/16"
  vpc_name            = var.vpc_name
  cluster_name        = module.eks.cluster-name
  master_subnet_cidr  = ["10.0.48.0/20", "10.0.64.0/20", "10.0.80.0/20"]
  worker_subnet_cidr  = ["10.0.144.0/20", "10.0.160.0/20", "10.0.176.0/20"]
  public_subnet_cidr  = ["10.0.204.0/22", "10.0.208.0/22", "10.0.212.0/22"]
  private_subnet_cidr = ["10.0.228.0/22", "10.0.232.0/22", "10.0.236.0/22"]
}

module "bastion-host" {
  source                  = "./bastion-host"
  instance_type           = var.instance_type
  instance_ami            = var.instance-ami
  server-name             = var.server-name
  aws_key_pair_name       = var.aws_key_pair_name
  aws_key_pair_public_key = var.aws_key_pair_public_key
  vpc_id                  = module.vpc.vpc_id
  k8-subnet               = module.vpc.public_subnet[0]
}

module "eks" {
  source                        = "./cluster"
  vpc_id                        = module.vpc.vpc_id
  cluster-name                  = var.cluster-name
  kubernetes-server-instance-sg = module.bastion-host.kubernetes-server-instance-sg
  eks_subnets                   = flatten([module.vpc.master_subnet])
  worker_subnet                 = flatten([module.vpc.worker_node_subnet])
  subnet_ids                    = flatten([module.vpc.master_subnet, module.vpc.worker_node_subnet])
}

resource "aws_acm_certificate" "cert" {
  // has to be a wildcard all of the subdomains should be certified
  domain_name       = "*.${var.ingress_url}"
  validation_method = "DNS"

  tags = {
    Name        = var.cluster-name
  }

  lifecycle {
    create_before_destroy = true
  }
}