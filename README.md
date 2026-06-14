# AI SaaS Platform Infrastructure

This repository contains the AWS infrastructure foundation for the AI SaaS platform.

It is designed as an interview-ready, production-style infrastructure repo that shows how to separate Terraform bootstrap concerns from application platform infrastructure.

## Architecture Positioning

> I split infrastructure into a bootstrap layer and a platform layer. Bootstrap creates Terraform's operating foundation: remote state, locking, and GitHub OIDC roles. The dev platform then creates the actual AWS resources: VPC, EKS, ECR, RDS PostgreSQL, and Cognito. This avoids circular dependencies and allows GitHub Actions to use short-lived AWS credentials instead of static access keys.

## Repository Structure

```text
terraform/
  bootstrap/
    # Creates Terraform state backend and GitHub Actions IAM roles.

  environments/
    dev/
      # Creates the dev AWS platform.

  modules/
    cognito/
    ecr/
    eks/
    iam-github-oidc/
    rds-postgres/
    vpc/

.github/
  workflows/
    terraform-plan.yml
    terraform-apply.yml
```

## What Each Layer Owns

### Bootstrap Layer

Path:

```text
terraform/bootstrap
```

Creates:

- S3 bucket for Terraform remote state.
- DynamoDB table for Terraform state locking.
- GitHub Actions OIDC provider.
- Terraform plan IAM role.
- Terraform apply IAM role.

Bootstrap starts with local state because it creates the S3 bucket and DynamoDB table that later become the remote backend.

After bootstrap succeeds, bootstrap state is migrated to S3 using:

```powershell
terraform init -migrate-state
```

### Dev Platform Layer

Path:

```text
terraform/environments/dev
```

Creates:

- VPC across two Availability Zones.
- Public and private subnets.
- Internet Gateway and NAT Gateway.
- ECR repositories for application images.
- EKS cluster and managed node group.
- EKS OIDC provider for IRSA.
- RDS PostgreSQL in private subnets.
- Cognito User Pool and app client.
- Security groups and IAM roles required by the platform.

The dev layer uses the S3/DynamoDB backend created by bootstrap.

## Current AWS Account

This project is configured for:

```text
AWS Account: 274214918810
Region: us-east-1
Profile: ai-saas-dev
```

Always confirm the account before running Terraform:

```powershell
$env:AWS_PROFILE="ai-saas-dev"
aws sts get-caller-identity
```

## Bootstrap Runbook

Use this only when setting up Terraform's foundation.

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
$env:AWS_PROFILE="ai-saas-dev"
terraform init
terraform plan
terraform apply
```

After apply, migrate bootstrap state to S3:

```powershell
Copy-Item backend-s3.tf.example backend.tf
terraform init -migrate-state
```

If Terraform asks whether to copy local state to the new backend, answer:

```text
yes
```

Verify:

```powershell
terraform state list
terraform plan
```

Expected:

```text
No changes. Your infrastructure matches the configuration.
```

Get role ARNs for GitHub Actions:

```powershell
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

## Dev Platform Runbook

Use this when testing or recreating the dev AWS platform.

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\environments\dev
$env:AWS_PROFILE="ai-saas-dev"
terraform init -reconfigure
terraform fmt -recursive ..\..
terraform validate
terraform plan -var="database_password=StrongTempPassword123!"
```

Expected after the platform is destroyed:

```text
Plan: 43 to add, 0 to change, 0 to destroy.
```

Apply only when you want to create paid AWS resources:

```powershell
terraform apply -var="database_password=StrongTempPassword123!"
```

Verify EKS after apply:

```powershell
aws eks update-kubeconfig --region us-east-1 --name ai-saas-platform-dev --profile ai-saas-dev
kubectl get nodes
kubectl get pods -A
```

Destroy when finished testing:

```powershell
terraform destroy -var="database_password=StrongTempPassword123!"
```

## GitHub Actions Setup

Add these repository secrets in GitHub:

```text
DATABASE_PASSWORD
TERRAFORM_PLAN_ROLE_ARN
TERRAFORM_APPLY_ROLE_ARN
```

Workflow behavior:

- Pull requests run Terraform format, init, validate, and plan.
- Apply is manual through `workflow_dispatch`.
- Apply should be protected with a GitHub environment such as `dev`.

Do not run apply from GitHub until the S3 backend is enabled and the role ARN secrets are configured.

## What Not To Commit

Never commit generated state, plans, local variables, or provider cache:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
*.auto.tfvars
tfplan
*.tfplan
```

Safe to commit:

```text
.terraform.lock.hcl
backend.tf
backend-s3.tf.example
*.tf
*.md
.github/workflows/*.yml
```

## EKS Blueprints Addons

Optional examples are included:

```text
terraform/environments/dev/eks-blueprints-addons.tf.example
terraform/environments/dev/eks-blueprints-providers.tf.example
```

Use them after the base EKS cluster exists.

Recommended sequence:

```text
1. Apply base AWS infrastructure.
2. Confirm kubectl can reach EKS.
3. Rename the Blueprints example files from .tf.example to .tf.
4. Apply add-ons such as AWS Load Balancer Controller, EBS CSI, metrics-server, and External Secrets.
```

Interview framing:

> EKS Blueprints Addons standardizes the EKS platform add-on layer. I still keep VPC, EKS, ECR, RDS, Cognito, and IAM explicit in Terraform, then use Blueprints Addons for operational add-ons like AWS Load Balancer Controller, EBS CSI, metrics-server, External Secrets, ExternalDNS, and cert-manager.

## Key Interview Points

- Terraform is declarative, reviewable, and repeatable.
- S3 remote state gives shared durable state.
- DynamoDB locking prevents concurrent Terraform applies.
- Bootstrap avoids circular dependency between Terraform, remote state, and GitHub Actions identity.
- GitHub Actions uses OIDC, not long-lived AWS access keys.
- EKS worker nodes and RDS run in private subnets.
- Public subnets support internet-facing load balancers and NAT.
- Cognito provides managed authentication.
- EKS OIDC enables IRSA for Kubernetes service accounts.

## Cost Guardrail

The dev platform creates paid resources, especially:

- EKS control plane.
- EC2 worker nodes.
- NAT Gateway.
- RDS PostgreSQL.
- EBS volumes.

Use `terraform destroy` when finished testing the dev platform. Keep bootstrap resources because they are low cost and required for remote state and GitHub Actions.
