variable "region" {
  description = "Region to deploy the terraform state"
  default     = "ap-southeast-1"
}

# This should be the same variable you define in the root variables.tf
variable "cluster-name" {
  description = "Cluster Name"
  default     = "reaCluster"
}