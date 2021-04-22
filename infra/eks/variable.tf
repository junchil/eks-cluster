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

variable "instance-ami" {
  default = "ami-08fdde86b93accf1c"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "cluster-name" {
  description = "Cluster Name"
  default     = "reaCluster"
}

variable "server-name" {
  description = "Ec2 Server Name"
  default     = "reaServer-bastion-host"
}

variable "vpc_name" {
  description = "VPC name"
  default     = "reaVpc"
}

variable "ingress_url" {
  default = "stevejcliu.com"
}
