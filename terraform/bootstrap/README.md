# Terraform Bootstrap

This layer owns the resources Terraform and GitHub Actions need before the dev platform can be managed safely.

## What It Creates

- S3 bucket for Terraform remote state.
- DynamoDB table for Terraform state locking.
- GitHub Actions OIDC provider.
- Terraform plan IAM role.
- Terraform apply IAM role.

It does not create application infrastructure such as VPC, EKS, RDS, Cognito, or ECR.

## Why This Exists

Bootstrap solves the Terraform chicken-and-egg problem:

```text
GitHub Actions needs AWS IAM roles before it can run Terraform.
Terraform needs remote state and locking before it is safe for CI/team use.
```

The dev environment then uses this foundation to create the actual platform.

## Clean Bootstrap Flow

Bootstrap starts with local state because it creates the S3 bucket and DynamoDB table used by Terraform backends.

```text
terraform/bootstrap
  local state first
  create S3 + DynamoDB + GitHub OIDC roles
  optionally migrate bootstrap state to S3 afterward
```

## If Manual Resources Already Exist

If these resources were created manually first:

```text
S3 bucket: sarandoniparthi-ai-saas-tfstate-dev-274214918810
DynamoDB table: ai-saas-platform-dev-tf-locks
```

Either import them into bootstrap state or delete them and let bootstrap create them cleanly.

## Runbook

### 1. First Bootstrap Apply

Bootstrap starts without an S3 backend because it creates the backend resources.

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
$env:AWS_PROFILE="ai-saas-dev"
terraform init
```

For the clean flow, run:

```powershell
terraform plan
terraform apply
```

After apply, capture outputs:

```powershell
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

### 2. Migrate Bootstrap State To S3

After bootstrap creates the S3 bucket and DynamoDB lock table, migrate bootstrap's own state to S3.

Copy the example backend file:

```powershell
Copy-Item backend-s3.tf.example backend.tf
```

Then run:

```powershell
terraform init -migrate-state
```

If asked to copy local state to the new backend, answer `yes`.

Verify:

```powershell
terraform state list
terraform plan
```

Expected:

```text
No changes. Your infrastructure matches the configuration.
```

### 3. Commit Rules

Commit:

```text
backend.tf
backend-s3.tf.example
.terraform.lock.hcl
*.tf
README.md
```

Do not commit:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
tfplan
```

## Interview Explanation

> I split bootstrap from platform infrastructure. Bootstrap owns Terraform's operating foundation: remote state, state locking, and GitHub OIDC IAM roles. The dev environment owns the product infrastructure: VPC, EKS, RDS, Cognito, and ECR. This avoids circular dependencies and lets CI/CD use short-lived AWS credentials instead of static access keys.
