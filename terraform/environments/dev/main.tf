module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project_name
  repositories = var.ecr_repositories
}

module "eks" {
  source = "../../modules/eks"

  project_name       = var.project_name
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  cluster_version    = var.eks_cluster_version
}

module "postgres" {
  source = "../../modules/rds-postgres"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  allowed_security_group_ids = {
    eks_cluster = module.eks.cluster_security_group_id
  }
  database_password   = var.database_password
  deletion_protection = var.postgres_deletion_protection
  skip_final_snapshot = var.postgres_skip_final_snapshot
}

module "cognito" {
  source = "../../modules/cognito"

  project_name  = var.project_name
  environment   = var.environment
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
}

module "github_oidc" {
  source = "../../modules/iam-github-oidc"

  project_name = var.project_name
  environment  = var.environment
  github_subjects = [
    "repo:${var.github_owner}/${var.github_infra_repo}:*"
  ]
}
