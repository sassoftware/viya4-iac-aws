# IPv6 Support in viya4-iac-aws

## Table of Contents

- [IPv6 Support in viya4-iac-aws](#ipv6-support-in-viya4-iac-aws)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Background](#background)
  - [Features](#features)
    - [Automated IPv6 Infrastructure](#automated-ipv6-infrastructure)
    - [EKS IPv6 Configuration](#eks-ipv6-configuration)
    - [RDS Dual-Stack Support](#rds-dual-stack-support)
    - [AWS Load Balancer Controller Automation](#aws-load-balancer-controller-automation)
  - [Prerequisites](#prerequisites)
    - [Required IAM Policy for IPv6 CNI](#required-iam-policy-for-ipv6-cni)
      - [Manual Policy Creation Steps](#manual-policy-creation-steps)
      - [Policy Attachment](#policy-attachment)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [Docker Deployment](#docker-deployment)
    - [Key Variables](#key-variables)
    - [What Gets Deployed](#what-gets-deployed)
  - [Version Compatibility](#version-compatibility)
  - [Limitations](#limitations)
  - [References](#references)

## Overview

This document describes the IPv6 support implementation in viya4-iac-aws, which automates the creation of AWS EKS clusters with IPv6-only Pod and Service CIDRs. This implementation addresses the challenges and requirements documented in the SAS internal research on ["Creating an AWS EKS cluster with IPv6-only Pod and Service CIDRs"](https://rndconfluence.sas.com/display/FNDSVCS/Creating+an+AWS+EKS+cluster+with+IPv6-only+Pod+and+Service+CIDRs).

## Background

AWS EKS supports single-stack IPv6 for Pods and Services (unlike Azure and GCP which only support dual-stack). However, IPv6 EKS clusters have specific requirements:

1. **AWS Load Balancer Controller Required**: The deprecated in-tree AWS LBC cannot create IPv6-compatible Network Load Balancers
2. **NLB Target Type**: IPv6 NLBs must use "ip" targets instead of "instance" targets
3. **cert-manager Dependency**: Required for AWS Load Balancer Controller webhook certificates

## Features

### Automated IPv6 Infrastructure
- **VPC IPv6 Support**: Automatic IPv6 CIDR block assignment
- **Subnet Configuration**: IPv6 CIDR blocks for all subnet types (public, private, database, control_plane)
- **Routing**: IPv6 routes via Internet Gateway (public) and Egress-only Gateway (private)
- **Security Groups**: Dual-stack rules supporting both IPv4 and IPv6 traffic

### EKS IPv6 Configuration
- **Cluster IP Family**: Automatically set to "ipv6" when IPv6 is enabled
- **CNI IPv6 Policy**: Manual creation required (see [Prerequisites](#prerequisites) below)
- **Dual-Stack VPC CNI**: IPv4 is enabled in VPC CNI alongside IPv6 for CSI driver compatibility
- **Compatible Node Groups**: All node groups support IPv6 addressing

### RDS Dual-Stack Support
- **PostgreSQL IPv6**: RDS instances automatically configured with dual-stack (IPv4 + IPv6) when IPv6 is enabled
- **Internal Connectivity**: IPv6 pods can connect to RDS using either IPv4 or IPv6
- **Database Subnets**: Dual-stack subnets with proper IPv6 routing

### AWS Load Balancer Controller Automation
- **Automatic Installation**: Deployed when `enable_ipv6 = true`
- **IRSA Configuration**: Proper IAM Roles for Service Accounts setup
- **cert-manager Dependency**: Automatically installed and configured with wait conditions
- **IPv6 NLB Support**: Enables creation of IPv6-compatible Network Load Balancers
- **Deployment Stability**: 60-second wait between cert-manager and controller ensures webhook readiness

## Prerequisites

### Required IAM Policy for IPv6 CNI

Before deploying an IPv6 EKS cluster, you must manually create the `AmazonEKS_CNI_IPv6_Policy` IAM policy in your AWS account. This policy is required **once per AWS account** and can be shared across all IPv6 EKS clusters.

**Why is this policy required?**

The AWS VPC CNI plugin needs additional permissions to assign IPv6 addresses to pods. Unlike IPv4, which uses RFC 1918 private addresses, IPv6 addresses must be assigned from the VPC's IPv6 CIDR block. This policy grants the CNI plugin permissions to:
- Assign IPv6 addresses to pod network interfaces
- Describe EC2 instances and network interfaces for topology information
- Create tags on network interfaces for proper resource tracking

**Important**: This project does NOT automatically create this policy to prevent naming conflicts when deploying multiple clusters in the same AWS account. Each AWS account requires only one instance of this policy.

#### Manual Policy Creation Steps

**Option 1: Using AWS Console**

1. Navigate to IAM → Policies → Create Policy
2. Select the JSON tab
3. Paste the following policy document:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AssignDescribe",
            "Effect": "Allow",
            "Action": [
                "ec2:AssignIpv6Addresses",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateTags",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        }
    ]
}
```

4. Name the policy: `AmazonEKS_CNI_IPv6_Policy`
5. Add description: "IAM policy for EKS CNI to assign IPv6 addresses to pods"
6. Create the policy

**Option 2: Using AWS CLI**

```bash
# Create policy document file
cat > eks-cni-ipv6-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AssignDescribe",
            "Effect": "Allow",
            "Action": [
                "ec2:AssignIpv6Addresses",
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DescribeInstanceTypes"
            ],
            "Resource": "*"
        },
        {
            "Sid": "CreateTags",
            "Effect": "Allow",
            "Action": "ec2:CreateTags",
            "Resource": "arn:aws:ec2:*:*:network-interface/*"
        }
    ]
}
EOF

# Create the IAM policy
aws iam create-policy \
    --policy-name AmazonEKS_CNI_IPv6_Policy \
    --description "IAM policy for EKS CNI to assign IPv6 addresses to pods" \
    --policy-document file://eks-cni-ipv6-policy.json

# Note the policy ARN from the output
```

**Option 3: Using Terraform (outside this project)**

If you manage AWS infrastructure centrally, you can create this policy once in a shared Terraform workspace:

```hcl
resource "aws_iam_policy" "eks_cni_ipv6_policy" {
  name        = "AmazonEKS_CNI_IPv6_Policy"
  description = "IAM policy for EKS CNI to assign IPv6 addresses to pods"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AssignDescribe"
        Effect = "Allow"
        Action = [
          "ec2:AssignIpv6Addresses",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      },
      {
        Sid      = "CreateTags"
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "arn:aws:ec2:*:*:network-interface/*"
      }
    ]
  })
}
```

#### Policy Attachment

The EKS module will automatically attach this policy to the worker node IAM roles when `enable_ipv6 = true`. You do not need to manually attach the policy to roles.

## Usage

### Quick Start

1. **Create the IPv6 CNI Policy** (if not already created):
   - Follow the steps in [Prerequisites](#prerequisites) above
   - Required once per AWS account

2. **Set IPv6 Configuration**:
   ```hcl
   # In your terraform.tfvars
   enable_ipv6 = true
   ```

3. **Use IPv6 Example Template**:
   ```bash
   cp examples/sample-input-ipv6.tfvars terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

4. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

### Docker Deployment

When deploying with Docker, ensure you include a volume mount for the Helm cache. This prevents permission errors when Helm tries to download chart repositories:

```bash
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $(pwd)/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $HOME/.cache:/.cache \
  --volume $(pwd):/workspace \
  viya4-iac-aws apply -auto-approve \
  -var-file /workspace/terraform.tfvars \
  -state /workspace/terraform.tfstate
```

**Key addition**: `--volume $HOME/.cache:/.cache`

This volume mount:
- Persists Helm repository cache across Docker runs
- Prevents "permission denied" errors on `/.cache/helm/`
- Speeds up subsequent deployments
- Works in all environments (local, CI/CD, Kubernetes)

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_ipv6` | Enable IPv6 for VPC, subnets, and EKS | `false` |
| `lb_controller_version` | AWS Load Balancer Controller Helm chart version | `"3.3.0"` |
| `cert_manager_version` | cert-manager Helm chart version | `"v1.20.2"` |

### What Gets Deployed

When `enable_ipv6 = true`:

1. **VPC with IPv6**:
   - IPv6 CIDR block automatically assigned by AWS
   - Dual-stack subnets (IPv4 + IPv6) for all subnet types
   - IPv6 routing tables and gateways
   - Egress-only Internet Gateway for private subnet IPv6 egress

2. **EKS Cluster**:
   - IPv6 cluster IP family (single-stack IPv6 for pods/services)
   - IPv6 CNI configuration with dual-stack support
   - IPv6-compatible node groups
   - Automatic attachment of `AmazonEKS_CNI_IPv6_Policy` to worker roles

3. **RDS PostgreSQL (if configured)**:
   - Dual-stack network type (IPv4 + IPv6)
   - Database subnets with IPv6 CIDR blocks
   - Security group rules allowing pod-to-database traffic

4. **AWS Load Balancer Controller**:
   - cert-manager (prerequisite) with wait conditions
   - AWS Load Balancer Controller with 60s deployment delay
   - Proper IRSA (IAM Roles for Service Accounts) configuration
   - IPv6-enabled NLB support

5. **Security Groups**:
   - Separate IPv4 and IPv6 egress rules
   - Compatible with both protocol stacks
   - Intra-security-group communication for IPv6 pods

## Version Compatibility

- **Manual Policy Creation**: The `AmazonEKS_CNI_IPv6_Policy` must be created manually before deployment
- **Multi-Cluster Consideration**: One IPv6 CNI policy per AWS account is shared across all IPv6 EKS clusters
- **Regional Availability**: Ensure your AWS region supports IPv6 for EKS
- **RDS External Access**: IPv6 external access to RDS requires additional security group configuration (internal pod access works automatically)
- **AWS CLI**: 2.24.16+
- **Kubernetes**: 1.32+ (default)
- **AWS Load Balancer Controller**: 3.3.0+ (default)
- **cert-manager**: v1.20.2+ (default)

## Limitations

- **Single-stack Only**: AWS EKS does not support dual-stack (IPv4+IPv6) for Pods and Services
- **Regional Availability**: Ensure your AWS region supports IPv6 for EKS

## References

- [AWS EKS IPv6 Documentation](https://docs.aws.amazon.com/eks/latest/userguide/deploy-ipv6-cluster.html)
- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [SAS Internal Research](https://rndconfluence.sas.com/display/FNDSVCS/Creating+an+AWS+EKS+cluster+with+IPv6-only+Pod+and+Service+CIDRs)