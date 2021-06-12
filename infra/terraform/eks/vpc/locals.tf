locals {
  common_tags = {
    "comment" = "Managed by Terraform"
    # "module_ref" = lookup(data.external.git_release.result, "ref", "unknown")
    # "module_url" = lookup(data.external.git_release.result, "url", "unknown")
    # "module_sha" = lookup(data.external.git_release.result, "sha", "unknown")
  }
}

data "external" "git_release" {
  working_dir = path.module
  program     = ["bash", "scripts/get-branch.sh"]
}