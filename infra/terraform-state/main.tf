provider "aws" {
  region     = var.region
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "terraform-up-and-running-state-eks"
  # Enable versioning so we can see the full revision history of our
  # state files
  versioning {
    enabled = true
  }
  # Enable server-side encryption by default
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name = "${var.cluster-name}-terraform-state-bucket"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks-eks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    Name = "${var.cluster-name}-terraform-locks"
  }
}