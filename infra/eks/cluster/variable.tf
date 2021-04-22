#
# Variables Configuration
#
variable "cluster-name" {
}

variable "cluster_version" {
  description = "EKS cluster version. E.g. 1.11, 1.12"
  default     = "1.16"
}

variable "cluster_name_override" {
  description = "EKS cluster name override"
  default     = ""
}

variable "cluster_location" {
  description = "Used as a suffix in resource names to denote cluster deploy location"
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID "
}

variable "eks_subnets" {
  description = "Master subnet ids"
  type        = list(string)
}

variable "worker_subnet" {
  type = list(string)
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of all subnet in cluster"
}

variable "kubernetes-server-instance-sg" {
  description = "Kubenetes control server security group"
}

variable "worker_node_instance_type" {
  default = "t2.small"
}

variable "worker_node_instance_type_override" {
  default     = []
  description = "Mapping of {\"instance_type\": string, \"weight\": int} declarations.  Must include instance type from worker_node_instance_type if set."
}

variable "worker_node_autoscaling" {
  default     = true
  description = "Enable Autoscaling of worker nodes"
}

variable "worker_node_count_max" {
  default = 3
}

variable "worker_node_count_min" {
  default = 3
}

variable "worker_node_on_demand_base_capacity" {
  description = "Absolute minimum amount of desired capacity that must be fulfilled by on-demand instances. Default: 0"
  default     = 3
}

variable "worker_node_on_demand_percentage_above_base_capacity" {
  description = "Percentage split between on-demand and Spot instances above the base on-demand capacity. Default: 100.  If you leave it set to 100, the percentages are 100% for On-Demand and 0% for Spot Instances.  If you set it to 0, the percentages are 0% On-Demand and 100% Spot Instances."
  default     = 100
}

variable "worker_node_spot_allocation_strategy" {
  description = "How to allocate capacity across the Spot pools. Valid values: lowest-price, capacity-optimized. lowest-price may cause all nodes to be in the same pool"
  default     = "lowest-price"
}

variable "wait_for_cluster_cmd" {
  description = "Custom local-exec command to execute for determining if the eks cluster is healthy. Cluster endpoint will be available as an environment variable called ENDPOINT"
  type        = string
  default     = "until wget --no-check-certificate -O - -q $ENDPOINT/healthz >/dev/null; do sleep 4; done"
}