variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming and tagging."
  type        = string
  default     = "ai-saas-platform"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR range for the platform VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ecr_repositories" {
  description = "Application image repositories."
  type        = list(string)
  default     = ["backend-api", "frontend", "python-ai-api", "worker"]
}

variable "eks_cluster_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.34"
}

variable "database_password" {
  description = "Initial PostgreSQL password. Provide through tfvars or CI secrets."
  type        = string
  sensitive   = true
}

variable "postgres_deletion_protection" {
  description = "Whether deletion protection is enabled for dev PostgreSQL."
  type        = bool
  default     = false
}

variable "postgres_skip_final_snapshot" {
  description = "Whether to skip the final RDS snapshot during destroy in dev."
  type        = bool
  default     = true
}

variable "cognito_callback_urls" {
  description = "Allowed Cognito OAuth callback URLs."
  type        = list(string)
  default     = ["http://localhost:3000/auth/callback"]
}

variable "cognito_logout_urls" {
  description = "Allowed Cognito OAuth logout URLs."
  type        = list(string)
  default     = ["http://localhost:3000"]
}
