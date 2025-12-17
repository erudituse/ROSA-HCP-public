# ACK Controllers - Reference Guide

This document provides reference information for AWS Controllers for Kubernetes (ACK) deployed on your ROSA HCP cluster.

## Overview

ACK lets you define and manage AWS resources directly from Kubernetes. The following controllers are automatically deployed via the pipeline:

- **ACK-IAM**: Manages AWS IAM resources (roles, policies, users, groups)
- **ACK-RDS**: Manages AWS RDS resources (instances, clusters, parameter groups)

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Terraform (Stage 5)                          │
├─────────────────────────────────────────────────────────────────┤
│  module.ack_iam_roles                                           │
│  ├── IAM Policy: ACK-IAM permissions                           │
│  ├── IAM Role: ack-iam-controller-role (OIDC trust)            │
│  ├── IAM Policy: ACK-RDS permissions                           │
│  ├── IAM Role: ack-rds-controller-role (OIDC trust)            │
│  ├── K8s Namespace: ack-system                                 │
│  ├── K8s ServiceAccount: ack-iam-controller (with role ARN)    │
│  └── K8s ServiceAccount: ack-rds-controller (with role ARN)    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    ArgoCD (Stage 7)                             │
├─────────────────────────────────────────────────────────────────┤
│  Helm Charts (from aws-controllers-k8s.github.io)              │
│  ├── ack-iam-controller (uses existing ServiceAccount)         │
│  └── ack-rds-controller (uses existing ServiceAccount)         │
└─────────────────────────────────────────────────────────────────┘
```

## IAM Permissions

### ACK-IAM Controller Policy

The IAM controller has permissions to manage:
- IAM Roles (create, delete, update, tag)
- IAM Policies (create, delete, versions)
- IAM Users and Groups
- IAM Instance Profiles
- OIDC Providers
- Role policy attachments

### ACK-RDS Controller Policy

The RDS controller has permissions to manage:
- DB Instances (create, delete, modify, start, stop)
- DB Clusters (Aurora)
- DB Subnet Groups
- DB Parameter Groups
- DB Snapshots
- EC2 describe permissions (VPCs, subnets, security groups)

## Usage Examples

### Create an IAM Role

```yaml
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Role
metadata:
  name: my-app-role
  namespace: my-app
spec:
  name: my-app-role
  description: "IAM role for my application"
  assumeRolePolicyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Action": "sts:AssumeRole"
        }
      ]
    }
  tags:
    - key: Environment
      value: dev
    - key: ManagedBy
      value: ACK
```

### Create an IAM Policy

```yaml
apiVersion: iam.services.k8s.aws/v1alpha1
kind: Policy
metadata:
  name: my-app-policy
  namespace: my-app
spec:
  name: my-app-policy
  description: "Policy for my application"
  policyDocument: |
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject",
            "s3:PutObject"
          ],
          "Resource": "arn:aws:s3:::my-bucket/*"
        }
      ]
    }
```

### Create an RDS Instance

```yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBInstance
metadata:
  name: my-postgres
  namespace: my-app
spec:
  dbInstanceIdentifier: my-postgres-db
  dbInstanceClass: db.t3.micro
  engine: postgres
  engineVersion: "15"
  masterUsername: admin
  masterUserPassword:
    name: rds-master-password  # K8s Secret
    key: password
  allocatedStorage: 20
  storageType: gp3
  dbSubnetGroupName: my-db-subnet-group
  vpcSecurityGroupIDs:
    - sg-xxxxxxxxx
  publiclyAccessible: false
  multiAZ: false
  tags:
    - key: Environment
      value: dev
```

### Create a DB Subnet Group

```yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBSubnetGroup
metadata:
  name: my-db-subnet-group
  namespace: my-app
spec:
  name: my-db-subnet-group
  description: "Subnet group for RDS instances"
  subnetIDs:
    - subnet-xxxxxxxx
    - subnet-yyyyyyyy
    - subnet-zzzzzzzz
  tags:
    - key: Environment
      value: dev
```

### Create an Aurora Cluster

```yaml
apiVersion: rds.services.k8s.aws/v1alpha1
kind: DBCluster
metadata:
  name: my-aurora-cluster
  namespace: my-app
spec:
  dbClusterIdentifier: my-aurora-cluster
  engine: aurora-postgresql
  engineVersion: "15.4"
  masterUsername: admin
  masterUserPassword:
    name: aurora-master-password
    key: password
  dbSubnetGroupName: my-db-subnet-group
  vpcSecurityGroupIDs:
    - sg-xxxxxxxxx
  storageEncrypted: true
  deletionProtection: false
```

## Verification

### Check Controller Status

```bash
# Check pods
oc get pods -n ack-system

# Expected output:
# NAME                                  READY   STATUS    RESTARTS   AGE
# ack-iam-controller-xxxxxxxxx-xxxxx    1/1     Running   0          10m
# ack-rds-controller-xxxxxxxxx-xxxxx    1/1     Running   0          10m
```

### Check CRDs

```bash
# List ACK CRDs
oc get crd | grep services.k8s.aws

# Expected IAM CRDs:
# groups.iam.services.k8s.aws
# instanceprofiles.iam.services.k8s.aws
# openidconnectproviders.iam.services.k8s.aws
# policies.iam.services.k8s.aws
# roles.iam.services.k8s.aws
# users.iam.services.k8s.aws

# Expected RDS CRDs:
# dbclusterparametergroups.rds.services.k8s.aws
# dbclusters.rds.services.k8s.aws
# dbinstances.rds.services.k8s.aws
# dbparametergroups.rds.services.k8s.aws
# dbsubnetgroups.rds.services.k8s.aws
```

### Verify Service Account Annotations

```bash
# Check that service accounts have the correct IAM role ARN
oc get sa -n ack-system ack-iam-controller -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
oc get sa -n ack-system ack-rds-controller -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'
```

### Check Resource Status

```bash
# List all ACK-managed IAM resources
oc get roles.iam.services.k8s.aws -A
oc get policies.iam.services.k8s.aws -A

# List all ACK-managed RDS resources
oc get dbinstances.rds.services.k8s.aws -A
oc get dbclusters.rds.services.k8s.aws -A

# Describe a specific resource
oc describe dbinstance.rds.services.k8s.aws my-postgres -n my-app
```

## Troubleshooting

### Common Issues

#### 1. Controller pods in CrashLoopBackOff

**Cause**: Usually IAM role trust policy or permissions issue.

**Solution**:
```bash
# Check controller logs
oc logs -n ack-system -l app.kubernetes.io/name=ack-iam-controller

# Verify service account annotation
oc get sa -n ack-system ack-iam-controller -o yaml

# Check IAM role trust policy in AWS Console
```

#### 2. Resources stuck in "Creating" state

**Cause**: IAM permissions insufficient or AWS API error.

**Solution**:
```bash
# Check resource conditions
oc describe <resource-type> <resource-name> -n <namespace>

# Look for ACK.Terminal or ACK.ReferencesResolved conditions
# Check the controller logs for detailed error messages
```

#### 3. "AccessDenied" errors in logs

**Cause**: IAM policy missing required permissions.

**Solution**:
- Check the IAM policy attached to the controller role
- Verify the action is included in the policy
- Check for resource-level restrictions

#### 4. Service Account not assuming role

**Cause**: OIDC trust policy misconfigured.

**Solution**:
```bash
# Verify OIDC provider URL matches
terraform output -raw oidc_endpoint_url

# Check IAM role trust policy in AWS Console
# Ensure the trust policy references the correct OIDC provider and service account
```

### Useful Commands

```bash
# View all ACK resources across namespaces
oc get adopted -A
oc get fieldexports -A

# Get detailed resource status
oc get <resource> -o yaml | grep -A 20 status:

# Watch resource changes
oc get dbinstances.rds.services.k8s.aws -A -w

# Force reconciliation (delete and recreate)
oc delete <resource> <name> -n <namespace>
# Then recreate the resource
```

## Updating ACK Controllers

ACK controller versions are managed via ArgoCD. To update:

1. Update the `targetRevision` in the Helm Application manifests:
   - `Stacks/app/manifests/ack-controllers/ack-iam.yaml`
   - `Stacks/app/manifests/ack-controllers/ack-rds.yaml`

2. Commit and push the changes

3. ArgoCD will automatically sync the new versions

## Adding Additional ACK Controllers

To add more ACK controllers (e.g., S3, EC2, Lambda):

1. Add IAM policy and role in `Stacks/infra/modules/ack-iam-roles/main.tf`
2. Add service account in the same module
3. Create ArgoCD Application in `Stacks/app/manifests/ack-controllers/`
4. Update the ApplicationSet to include the new controller

## References

- [ACK Documentation](https://aws-controllers-k8s.github.io/community/docs/community/overview/)
- [ACK IAM Controller](https://aws-controllers-k8s.github.io/community/docs/tutorials/iam-example/)
- [ACK RDS Controller](https://aws-controllers-k8s.github.io/community/docs/tutorials/rds-example/)
- [ACK Helm Charts](https://gallery.ecr.aws/aws-controllers-k8s)
