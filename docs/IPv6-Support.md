# IPv6 Support in viya4-iac-aws

## Overview

This document describes the IPv6 support implementation in viya4-iac-aws, which automates the creation of AWS EKS clusters with IPv6-only Pod and Service CIDRs. This implementation addresses the challenges and requirements documented in the SAS internal research on ["Creating an AWS EKS cluster with IPv6-only Pod and Service CIDRs"](https://rndconfluence.sas.com/display/FNDSVCS/Creating+an+AWS+EKS+cluster+with+IPv6-only+Pod+and+Service+CIDRs).

## Background

AWS EKS supports single-stack IPv6 for Pods and Services (unlike Azure and GCP which only support dual-stack). However, IPv6 EKS clusters have specific requirements:

1. **AWS Load Balancer Controller Required**: The deprecated in-tree AWS LBC cannot create IPv6-compatible Network Load Balancers
2. **NLB Target Type**: IPv6 NLBs must use "ip" targets instead of "instance" targets
3. **cert-manager Dependency**: Required for AWS Load Balancer Controller webhook certificates

## Features

### ✅ Automated IPv6 Infrastructure
- **VPC IPv6 Support**: Automatic IPv6 CIDR block assignment
- **Subnet Configuration**: IPv6 CIDR blocks for all subnet types (public, private, database, control_plane)
- **Routing**: IPv6 routes via Internet Gateway (public) and Egress-only Gateway (private)
- **Security Groups**: Dual-stack rules supporting both IPv4 and IPv6 traffic

### ✅ EKS IPv6 Configuration
- **Cluster IP Family**: Automatically set to "ipv6" when IPv6 is enabled
- **CNI IPv6 Policy**: Required IAM policy for IPv6 pod networking
- **Compatible Node Groups**: All node groups support IPv6 addressing

### ✅ AWS Load Balancer Controller Automation
- **Automatic Installation**: Deployed when `enable_ipv6 = true`
- **IRSA Configuration**: Proper IAM Roles for Service Accounts setup
- **cert-manager Dependency**: Automatically installed and configured
- **IPv6 NLB Support**: Enables creation of IPv6-compatible Network Load Balancers

## Usage

### Quick Start

1. **Set IPv6 Configuration**:
   ```hcl
   # In your terraform.tfvars
   enable_ipv6 = true
   ```

2. **Use IPv6 Example Template**:
   ```bash
   cp examples/sample-input-ipv6.tfvars terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform apply -var-file=terraform.tfvars
   ```

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_ipv6` | Enable IPv6 for VPC, subnets, and EKS | `false` |
| `lb_controller_version` | AWS Load Balancer Controller Helm chart version | `"1.6.2"` |
| `cert_manager_version` | cert-manager Helm chart version | `"v1.13.2"` |

### What Gets Deployed

When `enable_ipv6 = true`:

1. **VPC with IPv6**:
   - IPv6 CIDR block automatically assigned by AWS
   - Dual-stack subnets (IPv4 + IPv6)
   - IPv6 routing tables and gateways

2. **EKS Cluster**:
   - IPv6 cluster IP family
   - IPv6 CNI configuration
   - IPv6-compatible node groups

3. **AWS Load Balancer Controller**:
   - cert-manager (prerequisite)
   - AWS Load Balancer Controller
   - Proper IRSA (IAM Roles for Service Accounts) configuration

4. **Security Groups**:
   - Separate IPv4 and IPv6 egress rules
   - Compatible with both protocol stacks

## Integration with viya4-deployment

This IPv6 EKS cluster is designed to work with the `ipv6` feature branch of viya4-deployment. Set the following in your `ansible-vars.yaml`:

```yaml
V4_CFG_ENABLE_IPV6: true
```

The AWS Load Balancer Controller installed by this project will automatically handle the IPv6 NLB requirements for ingress-nginx.

## Troubleshooting

### Common Issues

1. **Ingress Not Working**: Ensure you're using the viya4-deployment `ipv6` branch which configures ingress-nginx for IPv6
2. **NLB Creation Fails**: The AWS Load Balancer Controller should be automatically installed; verify it's running in `kube-system` namespace
3. **IPv6 Connectivity**: Ensure your local network and AWS Security Groups allow IPv6 traffic

### Verification Commands

```bash
# Check IPv6 is enabled on cluster
kubectl get nodes -o wide

# Verify AWS Load Balancer Controller is running
kubectl get pods -n kube-system | grep aws-load-balancer-controller

# Check cert-manager is running
kubectl get pods -n kube-system | grep cert-manager

# Verify VPC has IPv6 CIDR
aws ec2 describe-vpcs --vpc-ids <vpc-id> --query 'Vpcs[0].Ipv6CidrBlockAssociationSet'
```

## Version Compatibility

- **Terraform**: 1.10.5+
- **kubectl**: 1.32.6+
- **AWS CLI**: 2.24.16+
- **Kubernetes**: 1.32+ (default)
- **AWS Load Balancer Controller**: 1.6.2+ (default)
- **cert-manager**: v1.13.2+ (default)

## Limitations

- **Single-stack Only**: AWS EKS does not support dual-stack (IPv4+IPv6) for Pods and Services
- **viya4-deployment Dependency**: Requires the `ipv6` feature branch for proper ingress configuration
- **Regional Availability**: Ensure your AWS region supports IPv6 for EKS

## References

- [AWS EKS IPv6 Documentation](https://docs.aws.amazon.com/eks/latest/userguide/deploy-ipv6-cluster.html)
- [AWS Load Balancer Controller Documentation](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [SAS Internal Research](https://rndconfluence.sas.com/display/FNDSVCS/Creating+an+AWS+EKS+cluster+with+IPv6-only+Pod+and+Service+CIDRs)