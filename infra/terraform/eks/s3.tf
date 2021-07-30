resource "aws_s3_bucket" "westfarmers" {
  bucket = "${var.cluster-name}-object-store-bucket"
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

  # Lifecyle
  lifecycle_rule {
    id      = "log"
    enabled = true

    transition {
      days          = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

  tags = {
    Name = "${var.cluster-name}-object-store-bucket"
  }
}
