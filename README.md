# AI SaaS Platform Infra

This repo owns AWS infrastructure for the AI SaaS reference platform.

## Interview Message

> This repo represents the platform infrastructure boundary. Terraform provisions AWS resources, GitHub Actions validates and plans changes, and protected applies prevent uncontrolled production changes.

## Responsibilities

- Terraform remote state with S3 and DynamoDB locking.
- VPC with public and private subnets.
- Internet Gateway and NAT Gateway.
- Route tables and security groups.
- ECR repositories for application images.
- EKS cluster and managed node groups.
- EKS OIDC provider for IRSA.
- RDS PostgreSQL for application data.
- Cognito User Pool for managed authentication.
- EKS IAM roles and GitHub Actions OIDC roles.
- Infrastructure GitHub Actions.
- Optional EKS Blueprints Addons examples.

## Target Structure

```text
terraform/
  bootstrap/
  environments/
    dev/
    prod/
  modules/
    vpc/
    ecr/
    eks/
    rds-postgres/
    cognito/
    iam-github-oidc/
.github/
  workflows/
    terraform-plan.yml
    terraform-apply.yml
```

## EKS Blueprints Addons

This repo includes optional examples for EKS Blueprints Addons:

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

> EKS Blueprints Addons standardizes the cluster platform layer. I still keep VPC, EKS, ECR, RDS, Cognito, and IAM explicit in Terraform, then use Blueprints Addons to bootstrap common EKS operational components.

## Local Terraform Runbook

Use this flow when testing the dev infrastructure from your laptop.

### 1. Confirm AWS Account

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\environments\dev
$env:AWS_PROFILE="ai-saas-dev"
aws sts get-caller-identity
```

Expected account:

```text
274214918810
```

### 2. Bootstrap Remote State

Terraform state is stored in S3 and locked with DynamoDB.

S3 bucket:

```text
sarandoniparthi-ai-saas-tfstate-dev-274214918810
```

DynamoDB lock table:

```text
ai-saas-platform-dev-tf-locks
```

The bucket should have:

- Versioning enabled.
- Public access blocked.
- Server-side encryption enabled.

The DynamoDB table should use:

```text
Partition key: LockID
Type: String
Billing: PAY_PER_REQUEST
```

### 3. Initialize Or Reconfigure Terraform

Run this after the backend is first enabled or changed:

```powershell
terraform init -reconfigure
```

`terraform init` prepares the working directory by downloading providers, initializing modules, and configuring the backend.

`-reconfigure` tells Terraform:

> Forget the previous backend configuration for this local folder and initialize using the backend settings currently defined in `versions.tf`.

Use `-reconfigure` when moving from local state to S3 remote state, or when changing backend bucket, key, region, or lock table.

If Terraform asks whether to copy existing state:

- Answer `yes` if AWS resources still exist and the local state tracks them.
- Answer `no` only if the infrastructure was already destroyed or the local state is intentionally empty.

### 4. Validate And Plan

```powershell
terraform fmt -recursive ..\..
terraform validate
terraform plan -var="database_password=StrongTempPassword123!"
```

Expected after destroy:

```text
Plan: 43 to add, 0 to change, 0 to destroy.
```

### 5. Apply Only When You Want AWS Cost

```powershell
terraform apply -var="database_password=StrongTempPassword123!"
```

This creates paid AWS resources such as EKS, EC2 nodes, NAT Gateway, and RDS.

### 6. Verify EKS After Apply

```powershell
aws eks update-kubeconfig --region us-east-1 --name ai-saas-platform-dev --profile ai-saas-dev
kubectl get nodes
kubectl get pods -A
```

### 7. Destroy When Done Testing

```powershell
terraform destroy -var="database_password=StrongTempPassword123!"
```

Do not delete Terraform state manually. State is how Terraform knows what it owns.

## What Not To Commit

Never commit generated state, plans, or secrets:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
*.auto.tfvars
tfplan
*.tfplan
```

Commit this file:

```text
terraform/environments/dev/.terraform.lock.hcl
```

It locks provider versions and makes Terraform runs more repeatable.

## Bootstrap Runbook

Bootstrap owns the infrastructure Terraform and GitHub Actions need before the dev platform can be managed from CI.

Bootstrap creates:

- S3 bucket for Terraform remote state.
- DynamoDB table for Terraform state locking.
- GitHub Actions OIDC provider.
- Terraform plan IAM role.
- Terraform apply IAM role.

Run from:

```powershell
cd C:\code\learning\ai-saas-platform-infra\terraform\bootstrap
$env:AWS_PROFILE="ai-saas-dev"
```

Bootstrap starts with local state because it creates the S3 bucket and DynamoDB lock table used by remote backends.

If the S3 bucket and DynamoDB table were created manually first, either import them into bootstrap state or delete them and let bootstrap create them cleanly.

For a clean bootstrap run:

```powershell
terraform init
terraform plan
terraform apply
```

After bootstrap creates the bucket and lock table, migrate bootstrap state to S3:

```powershell
Copy-Item backend-s3.tf.example backend.tf
terraform init -migrate-state
terraform state list
terraform plan
terraform output terraform_plan_role_arn
terraform output terraform_apply_role_arn
```

After migration, commit `terraform/bootstrap/backend.tf` and `terraform/bootstrap/.terraform.lock.hcl`. Do not commit `.terraform/`, `terraform.tfstate`, or `terraform.tfstate.backup`.

Add the role ARN outputs to GitHub Actions secrets:

```text
TERRAFORM_PLAN_ROLE_ARN
TERRAFORM_APPLY_ROLE_ARN
DATABASE_PASSWORD
```

## Explain This In Interviews

Terraform is used because infrastructure changes need to be declarative, reviewable, and repeatable. State is stored remotely so teams can collaborate safely, and locking prevents two applies from changing the same infrastructure at once. EKS worker nodes and RDS PostgreSQL run in private subnets because application compute and databases should not be directly reachable from the internet. Public subnets are used for internet-facing load balancers and NAT gateways. Cognito provides the managed identity layer for user authentication. GitHub Actions uses OIDC-backed IAM roles so CI does not need long-lived AWS access keys.

## Success Checkpoints

- `terraform fmt` passes.
- `terraform validate` passes.
- `terraform plan` shows expected AWS resources.
- After approved apply, `aws eks update-kubeconfig` works.
- `kubectl get nodes` shows managed node group nodes.

## Cost Guardrail

Do not run `terraform apply` for EKS until region, node size, NAT Gateway cost, and destroy steps have been reviewed.
