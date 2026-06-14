variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_subjects" {
  description = "Allowed GitHub OIDC subject claims, for example repo:ORG/REPO:*."
  type        = list(string)
}

variable "github_oidc_thumbprints" {
  description = "Thumbprints for the GitHub Actions OIDC provider."
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

