resource "aws_s3_bucket" "westfarmers" {
  bucket = "${var.cluster_name}-object-store-bucket"
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
    Name = "${var.cluster_name}-object-store-bucket"
  }
}

resource "aws_s3_bucket" "mimir_admin" {
  bucket = "${var.cluster_name}-mimir-admin"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_alertmanager" {
  bucket = "${var.cluster_name}-mimir-alertmanager"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_tsdb" {
  bucket = ${var.cluster_name}-"mimir-tsdb"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_ruler" {
  bucket = "${var.cluster_name}-mimir-ruler"
  force_destroy = true
}