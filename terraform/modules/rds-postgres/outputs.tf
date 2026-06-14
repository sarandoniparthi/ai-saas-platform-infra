output "endpoint" {
  description = "PostgreSQL endpoint."
  value       = aws_db_instance.this.endpoint
}

output "database_name" {
  description = "Initial database name."
  value       = aws_db_instance.this.db_name
}

output "security_group_id" {
  description = "RDS security group ID."
  value       = aws_security_group.this.id
}

output "master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN for the RDS managed master user password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}
