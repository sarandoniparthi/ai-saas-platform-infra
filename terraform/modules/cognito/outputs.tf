output "user_pool_id" {
  description = "Cognito User Pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  description = "Cognito app client ID."
  value       = aws_cognito_user_pool_client.web.id
}

output "user_pool_domain" {
  description = "Cognito hosted UI domain prefix."
  value       = aws_cognito_user_pool_domain.this.domain
}

