variable "ssh_public_key" {
  default = ""
}

variable "vpc_id" {
  default = ""
}

variable "instance_type" {
  description = "instance type for K8s creation Server - Eg:t2.micro"
}

variable "instance_ami" {
  description = "AMI for Instance"
}

variable "aws_key_pair_name" {
  description = "AWS Key Pair Name of the EC2 Instance"
}

variable "aws_key_pair_public_key" {
  description = "AWS Key Pair Public Key of the EC2 Instance"
}

variable "server-name" {
}

variable "k8-subnet" {
}

