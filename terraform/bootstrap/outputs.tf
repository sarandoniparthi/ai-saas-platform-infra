output "state_bucket_name" {
  description = "S3 bucket used for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "lock_table_name" {
  description = "DynamoDB table used for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = module.github_oidc.github_oidc_provider_arn
}

output "terraform_plan_role_arn" {
  description = "Role ARN for Terraform plan workflows."
  value       = module.github_oidc.terraform_plan_role_arn
}

output "terraform_apply_role_arn" {
  description = "Role ARN for protected Terraform apply workflows."
  value       = module.github_oidc.terraform_apply_role_arn
}
