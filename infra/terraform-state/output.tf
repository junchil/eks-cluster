output "terraform_state" {
  description = "Name of the S3 bucket for maintaining Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_locks" {
  description = "Name of the DynamoDB table for maintaining Terraform state bucket locks"
  value       = aws_dynamodb_table.terraform_locks.id
}