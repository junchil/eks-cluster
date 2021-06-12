variable "region" {
  default = "ap-southeast-2"
}

variable "aws_key_pair_name" {
  description = "AWS Key Pair Name of the EC2 Instance"
  default     = "stevejc-ec2-test-key-pair"
}

variable "aws_key_pair_public_key" {
  description = "AWS Key Pair Public Key of the EC2 Instance"
  default     = "~/.ssh/stevejc-ec2-test-key-pair.pub"
}

variable "sub_ids" {
  default = []
}

variable "instance_ami" {
  default = "ami-08fdde86b93accf1c"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "cluster_name" {
  description = "Cluster Name"
  default     = "anycluster"
}

variable "server_name" {
  description = "Ec2 Server Name"
  default     = "anyserver-bastion-host"
}

variable "vpc_name" {
  description = "VPC name"
  default     = "anycluster-vpc"
}

variable "ingress_url" {
  default = "stevejcliu.com"
}
