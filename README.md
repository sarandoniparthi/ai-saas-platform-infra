# AI SaaS Platform Infra

This repo owns AWS infrastructure for the AI SaaS reference platform.

## Interview Message

> This repo represents the platform infrastructure boundary. Terraform provisions AWS resources, GitHub Actions validates and plans changes, and protected applies prevent uncontrolled production changes.

## Responsibilities

- Terraform remote state plan with S3 and DynamoDB.
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
