output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by EKS worker nodes."
  value       = module.vpc.private_subnet_ids
}

output "ecr_repository_urls" {
  description = "ECR repository URLs keyed by service name."
  value       = module.ecr.repository_urls
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "eks_cluster_version" {
  description = "EKS Kubernetes version."
  value       = module.eks.cluster_version
}

output "eks_oidc_provider_arn" {
  description = "EKS OIDC provider ARN used by IRSA and EKS add-ons."
  value       = module.eks.oidc_provider_arn
}

output "postgres_endpoint" {
  description = "RDS PostgreSQL endpoint."
  value       = module.postgres.endpoint
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID."
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito app client ID."
  value       = module.cognito.user_pool_client_id
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID attached to managed node groups by default."
  value       = module.eks.cluster_security_group_id
}

output "postgres_security_group_id" {
  description = "RDS PostgreSQL security group ID."
  value       = module.postgres.security_group_id
}

output "postgres_master_user_secret_arn" {
  description = "AWS Secrets Manager secret ARN for the RDS managed master user password."
  value       = module.postgres.master_user_secret_arn
}
