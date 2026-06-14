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

This project targets one isolated dev AWS account. The exact AWS account ID is intentionally not documented in this public README.

```text
AWS Account: dedicated dev sandbox account
Region: us-east-1
Profile: ai-saas-dev
```

Before running any Terraform command, explicitly select the AWS profile and verify the account:

```powershell
$env:AWS_PROFILE="ai-saas-dev"
aws sts get-caller-identity
```

Expected output should show the dev sandbox account configured on your machine:

```text
"Account": "<your-dev-aws-account-id>"
```

Why this matters:

> Terraform creates and destroys real AWS infrastructure. Checking `aws sts get-caller-identity` prevents accidentally deploying into a personal, work, or wrong sandbox account.

## Bootstrap Resources Explained

Bootstrap creates the infrastructure that Terraform and GitHub Actions need before the main platform can be safely managed.

### S3 State Bucket

Name pattern:

```text
<unique-prefix>-ai-saas-tfstate-dev-<account-or-random-suffix>
```

Purpose:

- Stores Terraform state remotely.
- Allows your laptop and GitHub Actions to use the same state.
- Keeps state out of GitHub source control.
- Uses versioning so previous state versions can be recovered.
- Uses server-side encryption.
- Blocks public access.

Interview explanation:

> Terraform state maps code resources to real AWS resource IDs. I store it in S3 because state must be durable, shared, encrypted, and separate from source code.

### DynamoDB Lock Table

Name:

```text
ai-saas-platform-dev-tf-locks
```

Purpose:

- Provides Terraform state locking.
- Prevents two Terraform runs from changing the same state at the same time.
- Protects against state corruption during concurrent applies.

Interview explanation:

> DynamoDB locking prevents concurrent Terraform applies. Without locking, two engineers or CI jobs could update the same infrastructure state at the same time and corrupt the state file.

### GitHub Actions OIDC Provider

Provider:

```text
token.actions.githubusercontent.com
```

Purpose:

- Allows GitHub Actions to authenticate to AWS.
- Avoids storing long-lived AWS access keys in GitHub.
- Uses short-lived credentials through `sts:AssumeRoleWithWebIdentity`.

Interview explanation:

> GitHub OIDC lets GitHub Actions request short-lived AWS credentials. This is safer than storing AWS access keys because there is no long-lived secret to rotate or leak.

### Terraform Plan Role

Role:

```text
ai-saas-platform-dev-terraform-plan
```

Purpose:

- Used by pull request checks.
- Runs `terraform fmt`, `terraform validate`, and `terraform plan`.
- Has read-only AWS access in this dev scaffold.
- Shows what would change without creating, updating, or deleting resources.

Interview explanation:

> The plan role is intentionally limited. Pull requests should be able to inspect infrastructure changes, but they should not be able to modify cloud resources.

### Terraform Apply Role

Role:

```text
ai-saas-platform-dev-terraform-apply
```

Purpose:

- Used only by manual approved apply workflows.
- Creates, updates, or destroys AWS resources.
- Is intentionally separated from the plan role.
- Should be protected using a GitHub environment such as `dev`.

Current dev scaffold note:

```text
The apply role uses AdministratorAccess for learning/bootstrap speed.
For production, replace this with least-privilege IAM policies.
```

Interview explanation:

> The apply role is separate from the plan role because applying infrastructure is a higher-risk operation. I protect apply with manual approval and environment controls, then reduce permissions toward least privilege for production.

## Bootstrap Runbook

Use this only when setting up Terraform's foundation.

### Step 1: Go To Bootstrap Folder

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
```

### Step 2: Select AWS Profile And Verify Account

```powershell
$env:AWS_PROFILE="ai-saas-dev"
aws sts get-caller-identity
```

Confirm:

```text
"Account": "<your-dev-aws-account-id>"
```

### Step 3: Initialize Bootstrap Locally

Bootstrap starts with local state because it creates the S3 bucket and DynamoDB table used by remote state.

```powershell
terraform init
```

### Step 4: Review Bootstrap Plan

```powershell
terraform plan
```

Expected first-time result:

```text
Plan: 10 to add, 0 to change, 0 to destroy.
```

### Step 5: Apply Bootstrap

```powershell
terraform apply
```

This creates the S3 bucket, DynamoDB table, GitHub OIDC provider, and Terraform plan/apply roles.

### Step 6: Migrate Bootstrap State To S3

After apply, copy the S3 backend example into a real backend file:

```powershell
Copy-Item backend-s3.tf.example backend.tf
```

Then migrate local bootstrap state into S3:

```powershell
terraform init -migrate-state
```

If Terraform asks whether to copy local state to the new backend, answer:

```text
yes
```

### Step 7: Verify Bootstrap State

```powershell
terraform state list
terraform plan
```

Expected:

```text
No changes. Your infrastructure matches the configuration.
```

### Step 8: Capture GitHub Actions Role ARNs

```powershell
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

Use these output values as GitHub Actions secrets.

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

After bootstrap creates the Terraform plan/apply roles, connect GitHub Actions to AWS.

### Step 1: Add Repository Secrets

Go to:

```text
GitHub repo -> Settings -> Secrets and variables -> Actions -> New repository secret
```

Add these secrets:

```text
DATABASE_PASSWORD
TERRAFORM_PLAN_ROLE_ARN
TERRAFORM_APPLY_ROLE_ARN
```

Where the role values come from:

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

Why secrets are used:

- `DATABASE_PASSWORD` is sensitive and should never be committed.
- Role ARNs are configuration values used by GitHub Actions to assume AWS roles.
- AWS access keys are not stored because authentication uses OIDC.

### Step 2: Create GitHub Environment

Go to:

```text
GitHub repo -> Settings -> Environments -> New environment
```

Create:

```text
dev
```

Add an environment protection rule:

```text
Required reviewers: yourself
```

Why this exists:

> The `dev` environment protects `terraform apply`. Pull requests can run plan automatically, but apply is a higher-risk action because it can create, change, or destroy AWS resources. GitHub environment approval adds a manual gate and audit trail.

This matches the apply workflow:

```yaml
environment: dev
```

### Step 3: Understand Workflow Behavior

Plan workflow:

```text
Trigger: pull_request
Role: TERRAFORM_PLAN_ROLE_ARN
Actions: terraform fmt, init, validate, plan
Purpose: review infrastructure changes before merge
```

Apply workflow:

```text
Trigger: workflow_dispatch
Role: TERRAFORM_APPLY_ROLE_ARN
Environment: dev
Actions: terraform init, apply
Purpose: manually approved infrastructure changes
```

Do not run apply from GitHub until the S3 backend is enabled and the role ARN secrets are configured.

Interview explanation:

> I use GitHub Actions with OIDC so CI does not need static AWS keys. Pull requests assume a read-oriented Terraform plan role and show the planned infrastructure changes. Applies are manual, use a separate apply role, and are protected by the GitHub `dev` environment so infrastructure changes require approval and leave an audit trail.

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
