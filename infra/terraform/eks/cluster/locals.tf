data "aws_region" "current" {
}

locals {
  name_prefix  = "${var.cluster_name}-${data.aws_region.current.name}"
  cluster_name = local.name_prefix
  common_tags = {
    "cluster_name" = var.cluster_name
    "comment"      = "Managed by Terraform"
    # "tf_module_ref" = lookup(data.external.git_release.result, "ref", "unknown")
    # "tf_module_url" = lookup(data.external.git_release.result, "url", "unknown")
    # "tf_module_sha" = lookup(data.external.git_release.result, "sha", "unknown")
  }
}

data "external" "git_release" {
  working_dir = path.module
  program     = ["bash", "scripts/get-branch.sh"]
}