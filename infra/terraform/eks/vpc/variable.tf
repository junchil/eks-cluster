#VPC
variable "create_vpc" {
  default = " "
}

variable "cluster_name" {
  description = "Cluster name"
}

variable "vpc_name" {
}

variable "cidr" {
  description = "The CIDR block for the VPC."
}

#subnet variable
variable "public_subnet_cidr" {
  description = "Kubernetes Public CIDR"
  type        = list(string)
}

variable "private_subnet_cidr" {
  type        = list(string)
  description = "Kubernetes Private CIDR"
  default     = []
}

