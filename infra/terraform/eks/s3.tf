resource "aws_s3_bucket" "mimir_admin" {
  bucket = "mimir-admin"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_alertmanager" {
  bucket = "mimir-alertmanager"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_tsdb" {
  bucket = "mimir-tsdb"
  force_destroy = true
}

resource "aws_s3_bucket" "mimir_ruler" {
  bucket = "mimir-ruler"
  force_destroy = true
}