output "github_oidc_provider_arn" {
  description = "GitHub Actions OIDC provider ARN."
  value       = aws_iam_openid_connect_provider.github.arn
}

output "terraform_plan_role_arn" {
  description = "Role ARN for Terraform plan workflows."
  value       = aws_iam_role.terraform_plan.arn
}

output "terraform_apply_role_arn" {
  description = "Role ARN for protected Terraform apply workflows."
  value       = aws_iam_role.terraform_apply.arn
}

