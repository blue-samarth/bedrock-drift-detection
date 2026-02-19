resource "aws_s3_bucket" "bedrock_analyzer_bucket" {
  bucket = local.bucket_name
  acl    = "private"

  versioning { enabled = true }
  force_destroy = true

  tags = {
    Name = "Bedrock Analyzer Bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "analysis_results" {
  bucket = aws_s3_bucket.bedrock_analyzer_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "analysis_results" {
  bucket = aws_s3_bucket.bedrock_analyzer_bucket.id

  rule {
    id     = "delete-old-reports"
    status = "Enabled"

    filter {
      prefix = "reports/"
    }

    expiration {
      days = 90
    }
  }
}