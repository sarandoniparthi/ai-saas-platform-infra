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

