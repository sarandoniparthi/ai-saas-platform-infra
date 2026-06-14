# Dev Environment Architecture

This diagram represents the current `dev` environment scaffold in this repo.

The current Terraform environment is:

```text
terraform/environments/dev
```

It composes these modules:

```text
terraform/modules/vpc
terraform/modules/ecr
terraform/modules/eks
terraform/modules/rds-postgres
terraform/modules/cognito
terraform/modules/iam-github-oidc
```

Bootstrap layer:

```text
terraform/bootstrap
```

Bootstrap owns:

```text
S3 remote state bucket
DynamoDB state lock table
GitHub Actions OIDC provider
Terraform plan/apply IAM roles
```

Optional EKS Blueprints Addons examples:

```text
terraform/environments/dev/eks-blueprints-addons.tf.example
terraform/environments/dev/eks-blueprints-providers.tf.example
```

## Standard AWS Dev Architecture

```mermaid
flowchart TB
  Users["Users / Browser"] --> ALB["Future AWS Application Load Balancer<br/>created by Kubernetes Ingress"]
  GitHub["GitHub Actions"] --> IAM["IAM<br/>GitHub OIDC Provider<br/>Terraform Plan / Apply Roles"]
  GitHub --> TF["Terraform Dev Environment"]
  TF --> State["S3 Remote State<br/>DynamoDB Locking"]
  Bootstrap["Terraform Bootstrap"] --> State
  Bootstrap --> IAM

  subgraph Account["AWS Account - Dev"]
    subgraph Region["Region: us-east-1"]
      IAM
      State
      Cognito["Amazon Cognito<br/>User Pool + App Client<br/>Managed Auth"]
      EKSCP["Amazon EKS<br/>Managed Control Plane"]
      ECR["Amazon ECR<br/>Container Images"]

      subgraph VPC["VPC: 10.20.0.0/16"]
        IGW["Internet Gateway"]

        subgraph AZA["Availability Zone A: us-east-1a"]
          PubA["Public Subnet A<br/>ALB / NAT"]
          NAT["NAT Gateway<br/>Outbound internet"]
          PrivA["Private Subnet A<br/>EKS worker nodes"]
          NodeA["EC2 Managed Node<br/>EKS Node Group"]
          PodA["Kubernetes Pods<br/>backend-api / future services"]
        end

        subgraph AZB["Availability Zone B: us-east-1b"]
          PubB["Public Subnet B<br/>ALB"]
          PrivB["Private Subnet B<br/>EKS worker nodes"]
          NodeB["EC2 Managed Node<br/>EKS Node Group"]
          PodB["Kubernetes Pods<br/>backend-api / future services"]
        end

        RDS["Amazon RDS for PostgreSQL<br/>Private DB subnet group<br/>Encrypted, not public<br/>Inbound 5432 from EKS SG"]
      end
    end
  end

  TF --> VPC
  TF --> EKSCP
  TF --> ECR
  TF --> Cognito
  TF --> IAM

  ALB --> PubA
  ALB --> PubB
  IGW --> PubA
  IGW --> PubB
  PubA --> NAT
  NAT --> PrivA
  NAT --> PrivB
  PrivA --> NodeA
  PrivB --> NodeB
  EKSCP --> NodeA
  EKSCP --> NodeB
  ECR --> NodeA
  ECR --> NodeB
  NodeA --> PodA
  NodeB --> PodB
  PodA --> RDS
  PodB --> RDS
  PodA --> Cognito
  PodB --> Cognito
```

## Simplified Interview Diagram

```mermaid
flowchart LR
  Users["Users"] --> ALB["AWS ALB<br/>public entry point"]
  ALB --> Ingress["Kubernetes Ingress<br/>HTTP routing rules"]
  Ingress --> Service["Kubernetes Service<br/>stable internal endpoint"]
  Service --> Pods["Application Pods<br/>on EKS private nodes"]
  Pods --> RDS["RDS PostgreSQL<br/>private database subnet group"]
  Pods --> Cognito["Cognito<br/>managed authentication"]
  CI["GitHub Actions<br/>OIDC to AWS"] --> ECR["ECR<br/>container images"]
  CI --> GitOps["GitOps Repo<br/>Helm image tag"]
  ECR --> Pods
  GitOps --> ArgoCD["ArgoCD<br/>reconciles EKS"]
  ArgoCD --> Pods
```

## Terraform Module Relationship

```mermaid
flowchart TB
  Dev["terraform/environments/dev<br/>composition layer"]
  BootstrapMod["terraform/bootstrap<br/>Terraform operating foundation"]

  Dev --> VPCMod["modules/vpc"]
  Dev --> ECRMod["modules/ecr"]
  Dev --> EKSMod["modules/eks"]
  Dev --> RDSMod["modules/rds-postgres"]
  Dev --> CognitoMod["modules/cognito"]
  BootstrapMod --> IAMMod["modules/iam-github-oidc"]
  BootstrapMod --> StateMod["S3 state bucket<br/>DynamoDB lock table"]

  VPCMod --> VPC["VPC<br/>public/private subnets<br/>IGW, NAT, route tables"]
  ECRMod --> ECR["ECR repositories<br/>backend-api, frontend<br/>python-ai-api, worker"]
  EKSMod --> EKS["EKS cluster<br/>managed node group<br/>cluster/node IAM roles<br/>cluster security group"]
  RDSMod --> RDS["RDS PostgreSQL<br/>DB subnet group<br/>DB security group"]
  CognitoMod --> Cognito["Cognito<br/>User Pool<br/>Web app client<br/>Hosted UI domain"]
  IAMMod --> IAM["IAM<br/>GitHub OIDC provider<br/>Terraform plan role<br/>Terraform apply role"]

  VPC --> EKS
  VPC --> RDS
  EKS --> RDS
```

## Interview Explanation

Use this version in interviews:

> In the current dev environment, Terraform composes separate VPC, ECR, EKS, PostgreSQL, Cognito, and IAM/OIDC modules. The VPC module creates public and private subnets, an internet gateway, NAT gateway, and route tables. EKS worker nodes and RDS PostgreSQL run in private subnets, which reduces direct internet exposure. PostgreSQL allows port 5432 only from the EKS cluster security group in this dev scaffold. ECR stores Docker images, Cognito provides managed user authentication, and GitHub Actions uses OIDC-backed IAM roles instead of long-lived AWS keys.

## EKS Blueprints Addons

We can use EKS Blueprints Addons after the base EKS cluster exists.

Role in this project:

```text
Terraform base modules
  -> VPC, EKS, ECR, RDS, Cognito, IAM
EKS Blueprints Addons
  -> AWS Load Balancer Controller
  -> EBS CSI driver
  -> metrics-server
  -> External Secrets
  -> optional ExternalDNS / cert-manager
GitOps repo
  -> application workloads through Helm + ArgoCD
```

Interview answer:

> I would use EKS Blueprints Addons for the EKS platform add-on layer, not to hide the whole infrastructure design. Our Terraform modules still own the base AWS foundation: VPC, EKS, ECR, RDS, Cognito, and IAM. Once the cluster exists, EKS Blueprints Addons can install standard operational add-ons like AWS Load Balancer Controller, EBS CSI, metrics-server, External Secrets, ExternalDNS, and cert-manager. That gives us AWS-recommended platform bootstrap patterns while keeping the core architecture explicit.

Implementation note:

> Apply base infrastructure first, then apply add-ons. Kubernetes and Helm providers need a reachable EKS cluster before they can install add-ons.

## Standard AWS Explanation

Use this when the interviewer asks about zones or production layout:

> The dev VPC is modeled across two Availability Zones. Each zone has a public subnet and a private subnet. Public subnets are used for internet-facing entry points like an Application Load Balancer and NAT. Private subnets run EKS worker nodes and application pods. RDS PostgreSQL is placed in a private database subnet group so it is not internet-facing. Cognito is not inside the VPC; it is a managed regional AWS identity service used by the frontend and backend for authentication. GitHub Actions authenticates to AWS through OIDC and assumes Terraform roles, avoiding static AWS access keys. This layout gives better availability, clearer network boundaries, and a standard AWS production pattern.

## Current Scope

Included now:

- Dev environment only.
- S3 remote state backend configured for dev.
- DynamoDB lock table configured for dev.
- VPC.
- Public subnets.
- Private subnets.
- Internet Gateway.
- NAT Gateway.
- Route tables.
- ECR repositories.
- EKS cluster.
- EKS managed node group.
- IAM roles for EKS and nodes.
- EKS OIDC provider for IRSA.
- GitHub Actions OIDC provider in bootstrap.
- Terraform plan/apply IAM roles in bootstrap.
- RDS PostgreSQL in private subnets.
- Cognito User Pool and app client.

Not included yet:

- `prod` environment.
- AWS Load Balancer Controller.
- ArgoCD installation.
- Kubernetes workloads deployed through Terraform.
- Redis, SQS, Bedrock, or monitoring resources.
