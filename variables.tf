variable "region" { default = "us-west-2" }
variable "project_name" { default = "Bedrock-Lambda-Project" }
variable "environment" { default = "development" }
variable "namespace" { default = "bedrock" }
variable "short_name" { default = "blp" }


variable "s3_bucket_name" { default = "bedrock-analyzer-bucket" }

variable "tf_state_bucket" {
  description = "S3 bucket with Terraform state"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.tf_state_bucket))
    error_message = "Invalid S3 bucket name."
  }
}
variable "dynamodb_table_name" { default = "scaler-terraform-locks" }
variable "bedrock_model_id" { default = "anthropic.claude-3-5-sonnet-20240620-v1:0" }
variable "log_retention_days" { default = 7 }