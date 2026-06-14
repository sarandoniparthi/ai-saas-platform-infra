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

  backend "s3" {
    bucket         = "sarandoniparthi-ai-saas-tfstate-dev-274214918810"
    key            = "ai-saas-platform/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ai-saas-platform-dev-tf-locks"
    encrypt        = true
  }
}
