terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Configure after creating the bootstrap S3 bucket and DynamoDB table.
  # backend "s3" {
  #   bucket         = "REPLACE_WITH_TF_STATE_BUCKET"
  #   key            = "ai-saas-platform/dev/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "REPLACE_WITH_TF_LOCK_TABLE"
  #   encrypt        = true
  # }
}
