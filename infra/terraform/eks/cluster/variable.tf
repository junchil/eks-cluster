variable "cluster_name" {
}

variable "cluster_version" {
  description = "EKS cluster version. E.g. 1.27, 1.28"
  default     = "1.29"
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

# variable "kubernetes_server_instance_sg" {
#   description = "Kubenetes control server security group"
# }

variable "worker_node_instance_type" {
  default = "t2.medium"
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

variable "kubernetes_namespace" {
  type        = string
  description = "Kubernetes namespace for selection"
}

variable "kubernetes_labels" {
  type        = map(string)
  description = "Key-value mapping of Kubernetes labels for selection"
  default     = {}
}

variable "oidc_provider_enabled" {
  type        = bool
  default     = false
  description = "Create an IAM OIDC identity provider for the cluster, then you can create IAM roles to associate with a service account in the cluster, instead of using kiam or kube2iam. For more information, see https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html"
}