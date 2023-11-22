data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
  account_id             = data.aws_caller_identity.current.account_id
  irsa_oidc_provider_url = replace(aws_iam_openid_connect_provider.default[0].arn, "/^(.*provider/)/", "")
}

data "external" "git_release" {
  working_dir = path.module
  program     = ["bash", "scripts/get-branch.sh"]
}