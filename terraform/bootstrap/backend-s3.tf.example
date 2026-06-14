terraform {
  backend "s3" {
    bucket         = "sarandoniparthi-ai-saas-tfstate-dev-274214918810"
    key            = "ai-saas-platform/bootstrap/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ai-saas-platform-dev-tf-locks"
    encrypt        = true
  }
}
