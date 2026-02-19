data "aws_caller_identity" "current" {}

locals {
  # AWS metadata
  aws_region = "us-west-2"

  # Project metadata
  project_name = coalesce(var.project_name, "Bedrock-Lambda-Project")
  short_name   = coalesce(var.short_name, "blp")
  environment  = coalesce(var.environment, "development")
  namespace    = coalesce(var.namespace, "bedrock")
  name_prefix  = "${local.short_name}-${local.environment}"

  # S3 bucket for Bedrock reports
  bucket_name = coalesce(var.s3_bucket_name, "${local.name_prefix}-bedrock-bucket")

  # Terraform state backend
  tf_state_bucket     = coalesce(var.tf_state_bucket, "scaler-terraform-backend")
  dynamodb_table_name = var.dynamodb_table_name != null ? var.dynamodb_table_name : "scaler-terraform-locks"

  # Lambda & Bedrock
  bedrock_model_id   = coalesce(var.bedrock_model_id, "anthropic.claude-3-5-sonnet-20240620-v1:0")
  log_retention_days = coalesce(var.log_retention_days, 7)
}