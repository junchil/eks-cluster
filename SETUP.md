## SETUP

Tools version:

- Terraform: 0.12.24
- Helm: 3.2.4

Manual setup for CICD pipeline, this is only needed for the initial setup.

1. Setup S3 bucket and dynamodb for terraform state, this requires you to run it manually.

```bash
cd infra/terraform-state/
terraform init
terraform plan
terraform apply -auto-approve
```

The s3 bucket and dynomadb are created successfully.
```
aws_dynamodb_table.terraform_locks: Creating...
aws_s3_bucket.terraform_state: Creating...
aws_dynamodb_table.terraform_locks: Still creating... [10s elapsed]
aws_s3_bucket.terraform_state: Still creating... [10s elapsed]
aws_dynamodb_table.terraform_locks: Creation complete after 12s [id=terraform-up-and-running-locks-eks]
aws_s3_bucket.terraform_state: Still creating... [20s elapsed]
aws_s3_bucket.terraform_state: Still creating... [30s elapsed]
aws_s3_bucket.terraform_state: Creation complete after 32s [id=terraform-up-and-running-state-eks]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

terraform_locks = terraform-up-and-running-locks-eks
terraform_state = terraform-up-and-running-state-eks
```

This s3 bucket and dynamodb are used in the eks/main.tf backend for terraform remote state control.

2. Travis environment variables setting

Need add your AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as travis envionment variblaes. They are used in .travis.yml.