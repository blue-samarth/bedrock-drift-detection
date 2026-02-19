terraform {
  required_version = "~> 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.27.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }
  }

  # backend "s3" {
  #   key     = "terraform.tfstate"
  #   encrypt = true
  # }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = "Sample VPC"
      ManagedBy   = "Terraform"
      Environment = "Testing"
    }
  }
}