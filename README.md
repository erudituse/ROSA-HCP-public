# ROSA HCP Infrastructure as Code

End-to-end IaC deployment for Red Hat OpenShift Service on AWS (ROSA) with Hosted Control Plane (HCP), ArgoCD GitOps, and platform components.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                     GitLab CI Pipeline (7 Stages)                   │
├─────────────────────────────────────────────────────────────────────┤
│  validate → plan → apply-vpc → apply-hcp → apply-ack-roles →       │
│                                bootstrap → gitops                   │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS Infrastructure                          │
├──────────────────────────┬──────────────────────────────────────────┤
│          VPC             │           ROSA HCP Cluster               │
│  ├── Public Subnets      │  ├── Hosted Control Plane               │
│  ├── Private Subnets     │  ├── Worker Nodes (Default Pool)        │
│  ├── NAT Gateways        │  ├── OIDC Provider                      │
│  └── VPC Endpoints       │  └── Operator IAM Roles                 │
├──────────────────────────┴──────────────────────────────────────────┤
│                      ACK IAM Roles (Terraform)                      │
│  ├── ACK-IAM Controller Role + Policy                              │
│  └── ACK-RDS Controller Role + Policy                              │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Platform Components (GitOps)                    │
├─────────────────────────────────────────────────────────────────────┤
│  ArgoCD → Logging Operator → External Secrets → OADP →             │
│           ACK-IAM → ACK-RDS                                        │
└─────────────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
.
├── .gitlab-ci.yml              # GitLab CI pipeline (7 stages)
├── README.md                   # This file
├── scripts/
│   └── wait-for-cluster.sh     # Cluster readiness script
└── Stacks/
    ├── config/                 # Environment configurations
    │   ├── dev.tfvars
    │   └── prod.tfvars
    ├── infra/                  # Terraform infrastructure
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   ├── providers.tf
    │   ├── backend.tf
    │   └── modules/
    │       ├── vpc/
    │       ├── hcp-cluster/
    │       ├── argocd-bootstrap/
    │       └── ack-iam-roles/  # ACK controller IAM roles
    ├── app/                    # ArgoCD applications
    │   ├── argocd/
    │   │   ├── projects/
    │   │   └── applicationsets/
    │   └── manifests/
    │       ├── logging-operator/
    │       ├── external-secrets/
    │       ├── oadp/
    │       └── ack-controllers/  # ACK-IAM & ACK-RDS
    └── docs/
        └── ack-reference.md    # ACK usage examples and troubleshooting
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.4.0
- ROSA CLI (`rosa`)
- Red Hat Cloud Services (RHCS) token
- GitLab account (for CI/CD)
- S3 bucket and DynamoDB table for Terraform state

## Quick Start

### 1. Clone the Repository

```bash
git clone https://gitlab.com/your-org/rosa-hcp.git
cd rosa-hcp
```

### 2. Configure Environment

Edit `Stacks/config/dev.tfvars` with your settings:

```hcl
stack_name  = "platform-hcp"
environment = "dev"
aws_region  = "us-east-1"
vpc_cidr    = "10.100.0.0/16"
# ... see file for all options
```

### 3. Initialize Terraform Backend

Create an S3 bucket and DynamoDB table for state:

```bash
# Create S3 bucket
aws s3 mb s3://my-terraform-state-bucket --region us-east-1

# Create DynamoDB table
aws dynamodb create-table \
    --table-name terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
```

### 4. Initialize Terraform

```bash
cd Stacks/infra

terraform init \
    -backend-config="bucket=my-terraform-state-bucket" \
    -backend-config="key=rosa-hcp/dev/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="dynamodb_table=terraform-locks"
```

### 5. Deploy Infrastructure

```bash
# Plan
terraform plan -var-file=../config/dev.tfvars

# Apply VPC
terraform apply -target=module.vpc -var-file=../config/dev.tfvars

# Apply HCP Cluster
terraform apply -target=module.hcp_cluster -var-file=../config/dev.tfvars

# Apply ACK IAM Roles (creates IAM roles + K8s service accounts)
terraform apply -target=module.ack_iam_roles -var-file=../config/dev.tfvars

# Bootstrap ArgoCD
terraform apply -target=module.argocd_bootstrap -var-file=../config/dev.tfvars
```

## GitLab CI/CD

### Required CI/CD Variables

Set these in GitLab CI/CD Settings:

| Variable | Description |
|----------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `RHCS_TOKEN` | Red Hat Cloud Services token |
| `ENV` | Environment (dev/prod) |
| `ARGOCD_TOKEN` | ArgoCD auth token (for gitops stage) |

### Pipeline Stages

1. **validate**: Format and validate Terraform
2. **plan**: Generate Terraform plan
3. **apply-infra**: Deploy VPC (manual)
4. **apply-cluster**: Deploy ROSA HCP cluster (manual)
5. **apply-ack-roles**: Create ACK IAM roles and K8s service accounts (manual)
6. **bootstrap**: Install ArgoCD (manual)
7. **gitops**: Sync ArgoCD applications including ACK controllers (manual)

## Platform Components

All components are deployed via the pipeline (Terraform + ArgoCD GitOps):

| Component | Deployment Method | Description |
|-----------|-------------------|-------------|
| **VPC** | Terraform | 3-AZ VPC with public/private subnets |
| **ROSA HCP Cluster** | Terraform | Hosted Control Plane cluster |
| **ACK IAM Roles** | Terraform | IAM roles for ACK controllers |
| **ArgoCD** | Terraform (OLM) | OpenShift GitOps operator |
| **Logging Operator** | ArgoCD | OpenShift Logging with Loki |
| **External Secrets** | ArgoCD | AWS Secrets Manager integration |
| **OADP** | ArgoCD | Backup/restore with Velero |
| **ACK-IAM** | ArgoCD (Helm) | AWS IAM resource management |
| **ACK-RDS** | ArgoCD (Helm) | AWS RDS resource management |

### ACK Controllers

ACK (AWS Controllers for Kubernetes) allows you to manage AWS resources directly from Kubernetes. The deployment is fully automated:

1. **Terraform** creates:
   - IAM policies with required permissions
   - IAM roles with OIDC trust policy
   - Kubernetes namespace (`ack-system`)
   - Service accounts with role ARN annotations

2. **ArgoCD** deploys:
   - ACK-IAM controller via Helm
   - ACK-RDS controller via Helm

See [Stacks/docs/ack-reference.md](Stacks/docs/ack-reference.md) for usage examples.

## Configuration Options

### Stack Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `stack_name` | Stack identifier | Required |
| `environment` | Environment (dev/staging/prod) | Required |

### VPC Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | Required |
| `azs` | Availability zones | Required |
| `private_subnet_cidrs` | Private subnet CIDRs | Required |
| `public_subnet_cidrs` | Public subnet CIDRs | Required |

### Cluster Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `cluster_name` | Cluster name | `{stack}-{env}` |
| `ocp_version` | OpenShift version | `4.14` |
| `compute_machine_type` | Worker node instance type | `m5.xlarge` |
| `replicas` | Number of worker nodes | `2` |
| `private_cluster` | Private API endpoint | `true` |

## Outputs

After deployment, get outputs with:

```bash
terraform output

# Specific outputs
terraform output cluster_api_url
terraform output argocd_server_url
terraform output ack_iam_controller_role_arn
terraform output ack_rds_controller_role_arn
```

## Cleanup

```bash
# Destroy all resources
terraform destroy -var-file=../config/dev.tfvars

# Or use GitLab CI destroy job (manual)
```

## Troubleshooting

### Cluster Not Ready

```bash
# Check cluster status
rosa describe cluster -c <cluster-name>

# Check logs
rosa logs install -c <cluster-name>
```

### ArgoCD Issues

```bash
# Check ArgoCD pods
oc get pods -n openshift-gitops

# Check application status
oc get applications -n openshift-gitops
```

### ACK Controller Issues

```bash
# Check ACK pods
oc get pods -n ack-system

# Check controller logs
oc logs -n ack-system -l app.kubernetes.io/name=ack-iam-controller
oc logs -n ack-system -l app.kubernetes.io/name=ack-rds-controller

# Verify service account annotations
oc get sa -n ack-system -o yaml | grep eks.amazonaws.com/role-arn
```

### Terraform State Issues

```bash
# Force unlock state
terraform force-unlock <lock-id>
```

## Contributing

1. Create a feature branch
2. Make changes
3. Submit merge request
4. Pipeline will validate changes

## License

Internal use only.
