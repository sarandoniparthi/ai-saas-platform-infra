variable "aws_region" {
  description = "AWS region for bootstrap resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "ai-saas-platform"
}

variable "environment" {
  description = "Environment name used for bootstrap resource names."
  type        = string
  default     = "dev"
}

variable "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  type        = string
  default     = "sarandoniparthi-ai-saas-tfstate-dev-274214918810"
}

variable "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  type        = string
  default     = "ai-saas-platform-dev-tf-locks"
}

variable "github_owner" {
  description = "GitHub organization or username that owns the infra repo."
  type        = string
  default     = "sarandoniparthi"
}

variable "github_infra_repo" {
  description = "GitHub infrastructure repository name."
  type        = string
  default     = "ai-saas-platform-infra"
}
