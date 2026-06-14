# Terraform Bootstrap

Bootstrap creates the foundation required to run Terraform safely from a laptop or GitHub Actions.

## What Bootstrap Creates

- S3 bucket for Terraform remote state.
- DynamoDB table for Terraform state locking.
- GitHub Actions OIDC provider.
- Terraform plan IAM role.
- Terraform apply IAM role.

It does not create the application platform. VPC, EKS, RDS, Cognito, and ECR are created by `terraform/environments/dev`.

## Why Bootstrap Starts Local

Bootstrap creates the remote backend, so it cannot depend on that backend before it exists.

The sequence is:

```text
1. Run bootstrap with local state.
2. Bootstrap creates S3, DynamoDB, and GitHub OIDC roles.
3. Copy backend-s3.tf.example to backend.tf.
4. Run terraform init -migrate-state.
5. Bootstrap state now lives in S3.
```

## Run Bootstrap

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
$env:AWS_PROFILE="ai-saas-dev"
terraform init
terraform plan
terraform apply
```

Outputs:

```powershell
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

## Migrate Bootstrap State To S3

After apply succeeds:

```powershell
Copy-Item backend-s3.tf.example backend.tf
terraform init -migrate-state
```

When prompted, answer:

```text
yes
```

Verify:

```powershell
terraform state list
terraform plan
```

Expected plan:

```text
No changes. Your infrastructure matches the configuration.
```

## GitHub Secrets

Add these GitHub Actions secrets using the Terraform outputs:

```text
TERRAFORM_PLAN_ROLE_ARN
TERRAFORM_APPLY_ROLE_ARN
```

The RDS master password is not stored in GitHub. The dev RDS module uses AWS-managed master credentials in Secrets Manager.

## GitHub Environment

Create a GitHub environment named:

```text
dev
```

Recommended protection:

```text
Required reviewers: yourself
```

The apply workflow references this environment:

```yaml
environment: dev
```

Why:

> Terraform apply can create, modify, or destroy AWS resources. A GitHub environment adds manual approval and an audit trail before the apply job can run.

## Commit Rules

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

> Bootstrap is the Terraform operating foundation. It creates S3 remote state, DynamoDB locking, and GitHub OIDC IAM roles before the main platform infrastructure runs. This avoids circular dependencies and lets CI/CD use short-lived AWS credentials instead of static access keys.
