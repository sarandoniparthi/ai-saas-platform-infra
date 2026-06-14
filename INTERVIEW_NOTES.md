# Infra Interview Notes

## What I Built

AWS infrastructure foundation for a production-style AI SaaS platform using Terraform, including a bootstrap layer for remote state and CI identity, plus a dev platform layer for networking, Kubernetes, container registry, PostgreSQL, Cognito authentication, and security groups.

## Why It Exists

The infrastructure layer creates stable cloud primitives before application deployment begins. It separates cloud ownership from application code and makes changes reviewable.

## How It Works

Terraform modules define reusable infrastructure. The bootstrap layer owns S3 remote state, DynamoDB locking, the GitHub OIDC provider, and Terraform plan/apply IAM roles. Environments such as dev and prod compose platform modules with environment-specific values. GitHub Actions runs format, validation, plan, and protected apply workflows by assuming IAM roles through OIDC. PostgreSQL is placed in private subnets, only allows traffic on port 5432 from the EKS cluster security group in the dev scaffold, and uses AWS-managed master credentials in Secrets Manager. Cognito provides managed authentication through a User Pool and app client.

EKS Blueprints Addons can be used after the base cluster exists to install standard EKS platform add-ons such as AWS Load Balancer Controller, EBS CSI, metrics-server, External Secrets, ExternalDNS, and cert-manager.

## Production Tradeoffs

- Private EKS worker nodes improve security but require NAT or VPC endpoints for outbound dependencies.
- NAT Gateway is operationally simple but can be expensive.
- Managed node groups reduce operational burden compared with self-managed nodes.
- OIDC avoids long-lived AWS credentials but requires correct trust policy setup.
- RDS is easier to operate than self-managed PostgreSQL but still requires backup, upgrade, and connection management decisions.
- Cognito reduces custom auth burden but requires careful callback URL, token, and app-client configuration.
- GitHub OIDC avoids long-lived AWS keys, but role trust policies must tightly restrict allowed repos and branches/environments.
- The dev apply role is broad for bootstrap convenience; production should replace it with least-privilege permissions.
- EKS Blueprints Addons accelerates cluster bootstrap, but it introduces Helm/Kubernetes provider dependencies and usually works best as a second step after the EKS cluster exists.

## Common Failure Modes

- Terraform state stored locally or lost.
- Concurrent applies without locking.
- Running GitHub Actions apply before remote state is configured.
- Saying no to state migration while real AWS resources still exist.
- Worker nodes placed in public subnets.
- IAM roles too broad.
- GitHub Actions using static AWS keys.
- EKS cluster created without a clear destroy plan.
- Database exposed publicly.
- Database password committed to Git or stored as a static CI secret instead of managed in AWS Secrets Manager.
- Cognito callback URLs misconfigured across local, dev, and prod.
- GitHub OIDC trust policy too broad, allowing untrusted repos or branches to assume AWS roles.
- CI workflows using static AWS keys instead of OIDC.
- Terraform apply workflow not protected with a GitHub environment approval.
- Trying to install EKS add-ons before Kubernetes/Helm providers can authenticate to the cluster.

## Interview Questions

1. Why use remote state?
2. Why use state locking?
3. What does `terraform init -reconfigure` do?
4. When should you migrate local state to S3?
5. Why private subnets for worker nodes?
6. What does the EKS control plane manage?
7. What belongs in IAM vs Kubernetes RBAC?
8. Why use GitHub OIDC?
9. Why put PostgreSQL in private subnets?
10. Why use Cognito instead of building custom authentication?
11. How does the RDS security group allow EKS traffic?
12. Why should the Terraform apply role be protected?
13. What role does EKS Blueprints Addons play?
14. Why apply base infrastructure before Kubernetes add-ons?
15. Why use GitHub Environments for Terraform apply?

## Terraform State Explanation

Terraform state maps code resources to real AWS resource IDs. Without state, Terraform cannot reliably know whether a VPC, EKS cluster, RDS instance, or IAM role already exists.

For this repo, the dev backend uses:

```text
S3 bucket: dedicated dev Terraform state bucket
State key: ai-saas-platform/dev/terraform.tfstate
DynamoDB lock table: ai-saas-platform-dev-tf-locks
```

`terraform init -reconfigure` is used when the backend configuration changes. In this project, it was used to move the dev environment from local state to an S3 backend. Reconfiguration does not create application infrastructure; it reconnects Terraform to the selected backend.

Interview answer:

> Terraform state is the source of truth that maps my configuration to real AWS resources. I use S3 for shared, durable, versioned state and DynamoDB for locking so two engineers or CI jobs cannot apply at the same time. When I moved from local state to S3, I used `terraform init -reconfigure` to force Terraform to initialize against the backend in `versions.tf`.

## Bootstrap Explanation

Bootstrap owns the foundation Terraform needs to run safely:

```text
S3 remote state
DynamoDB locking
GitHub OIDC provider
Terraform plan role
Terraform apply role
```

The dev environment owns the application platform:

```text
VPC
EKS
ECR
RDS PostgreSQL
Cognito
```

Interview answer:

> I separated bootstrap from platform infrastructure. Bootstrap creates Terraform's operating foundation: state storage, locking, and CI identity. The dev environment then creates the actual AWS platform. This avoids circular dependencies where GitHub Actions needs IAM roles before it can safely run Terraform.

## GitHub Actions Environment Explanation

The plan workflow runs automatically on pull requests and uses the Terraform plan role. The apply workflow is manual and uses the Terraform apply role.

The apply workflow is tied to a GitHub environment:

```text
dev
```

That environment should require reviewer approval.

Interview answer:

> I use GitHub Environments to protect Terraform apply. Pull requests can run plan automatically, but apply is connected to the `dev` environment and requires approval. This separates review from deployment, prevents accidental infrastructure changes, and creates an audit trail for who approved the change.

## 60-Second Explanation

This repo owns AWS infrastructure. Terraform provisions the VPC, networking, ECR, EKS, PostgreSQL, Cognito, security groups, IAM roles, and supporting resources. State should live remotely in S3 with DynamoDB locking so the team can collaborate safely. EKS worker nodes and RDS PostgreSQL run in private subnets, while public subnets support load balancers and NAT. PostgreSQL allows port 5432 from the EKS cluster security group. Cognito provides managed authentication through a User Pool and web app client. GitHub Actions assumes Terraform roles through OIDC, so we avoid static AWS keys and keep apply behind protected approval.

For EKS platform add-ons, I can use EKS Blueprints Addons after the base cluster exists. That installs common operational components like AWS Load Balancer Controller, EBS CSI, metrics-server, External Secrets, ExternalDNS, and cert-manager using AWS-supported Terraform patterns.

## Resume Bullet

Built a Terraform-managed AWS platform foundation with S3/DynamoDB remote state, VPC, private EKS worker nodes, ECR, RDS PostgreSQL, Cognito, security groups, GitHub OIDC IAM roles, and protected infrastructure workflows.

Optional enhanced bullet:

Designed an EKS platform bootstrap path using EKS Blueprints Addons for AWS Load Balancer Controller, EBS CSI, metrics-server, External Secrets, ExternalDNS, and cert-manager.
