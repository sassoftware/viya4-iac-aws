# SAS Viya 4 IaC AWS - AI Coding Agent Instructions

## Project Overview
This is a Terraform-based Infrastructure as Code project that provisions AWS resources for deploying SAS Viya 4 platform. It creates EKS clusters, VPCs, storage (EFS/FSx ONTAP/NFS), RDS PostgreSQL, and all supporting infrastructure.

**Key repos**: Use this for provisioning; [`viya4-deployment`](https://github.com/sassoftware/viya4-deployment) deploys SAS Viya after infrastructure is created.

## Architecture Patterns

### Module Structure
The project uses a root-and-modules pattern:
- **Root module** (`main.tf`, `variables.tf`, `outputs.tf`, `locals.tf`): Orchestrates all resources
- **Custom modules** (`modules/`): Reusable components for vpc, ebs_csi, autoscaling, fsx_ontap, vm, kubeconfig
- **External modules**: `terraform-aws-modules/eks/aws` (~> 20.0) for EKS cluster provisioning

### BYON (Bring Your Own Network) Tiers
The code supports 4 networking scenarios via `byon_tier` in `modules/aws_vpc/main.tf`:
- **Tier 0**: Create everything (VPC, subnets, security groups)
- **Tier 1**: Use existing VPC, create subnets and security groups
- **Tier 2**: Use existing VPC and subnets, create security groups
- **Tier 3**: Use all existing resources (VPC, subnets, security groups)

Logic determined by: `var.vpc_id`, `var.existing_subnet_ids`, `var.security_group_id`, `var.cluster_security_group_id`

### Variable Defaults & Validation
- `prefix` variable MUST start with lowercase letter, contain only lowercase alphanumeric and hyphens
- Extensive inline validation rules in `variables.tf` (e.g., lines 10-13 for prefix)
- Default values often use `null` to trigger conditional logic in `locals.tf`

### Locals Pattern
`locals.tf` contains critical derived values:
- CIDR aggregation: `cluster_endpoint_private_access_cidrs` merges public/private subnet CIDRs with user-provided CIDRs
- Security group selection: Chooses between created or existing resources
- Credential file handling: Supports both deprecated `aws_shared_credentials_file` (singular) and new `aws_shared_credentials_files` (list)

## Development Workflows

### Docker-First Development
**Recommended approach**: Run Terraform via Docker container to avoid local dependency management.

```bash
# Build image (includes Terraform 1.10.5, kubectl 1.32.6, AWS CLI 2.24.16)
docker build -t viya4-iac-aws .

# Run commands
docker run --rm --group-add root \
  --user "$(id -u):$(id -g)" \
  --env-file $HOME/.aws_docker_creds.env \
  --volume $HOME/.ssh:/.ssh \
  --volume $(pwd):/workspace \
  viya4-iac-aws plan -var-file /workspace/terraform.tfvars -state /workspace/terraform.tfstate
```

Entrypoint: `docker-entrypoint.sh` configures user/group and execs terraform.

### Native Terraform Workflow
```bash
terraform init
terraform plan       # Preview changes
terraform apply      # Create infrastructure
terraform output     # View outputs (includes kubeconfig path)
terraform destroy    # Teardown
```

### AWS Authentication Methods
Two mutually exclusive approaches (see `docs/user/TerraformAWSAuthentication.md`):
1. **Static credentials**: Set `TF_VAR_aws_access_key_id`, `TF_VAR_aws_secret_access_key`, `TF_VAR_aws_session_token` (for MFA/temporary creds)
2. **AWS Profile**: Set `TF_VAR_aws_profile`, optionally `TF_VAR_aws_shared_credentials_files`

Store credentials in `$HOME/.aws_creds.sh` or `$HOME/.aws_docker_creds.env` (Docker).

### Configuration Files
- **Example configs**: `examples/sample-input*.tfvars` show patterns (minimal, HA, GPU, multi-zone, BYO network)
- **Required variables**: Only `prefix` and `location` (default: `us-east-1`)
- **Recommended**: Set `default_public_access_cidrs` (empty `[]` blocks access), `ssh_public_key`

## Testing

### Unit Tests (Terratest)
Located in `test/defaultplan/` and `test/nondefaultplan/`:
- Use **table-driven test pattern** (Go map of `helpers.TestCase` structs)
- Validate `terraform plan` output WITHOUT provisioning resources (zero cost)
- Use JSONPath queries to extract values from plan (see `test/helpers/json_path.go`)

Example pattern from `test/defaultplan/default_unit_test.go`:
```go
tests := map[string]helpers.TestCase{
    "k8sVersionTest": {
        Expected:          "1.32",
        ResourceMapName:   "module.eks.aws_eks_cluster.this[0]",
        AttributeJsonPath: "{$.version}",
    },
}
helpers.RunTests(t, tests, helpers.GetDefaultPlan(t))
```

### Integration Tests
Located in `test/defaultapply/`:
- Run `terraform apply` to provision real resources (incurs AWS costs)
- Main test runners handle setup/teardown via deferred cleanup
- **Always use `E` suffix methods** (e.g., `terraform.ApplyE`) to handle errors gracefully and ensure cleanup runs

### Running Tests
```bash
cd test
go test ./defaultplan/...      # Unit tests
go test ./defaultapply/...     # Integration tests (provisions resources)
```

## Code Conventions

### Comments
Every Terraform resource/variable includes inline comments explaining purpose:
```terraform
variable "location" {
  description = "AWS Region to provision all resources in this script."  # User-facing
  type        = string
  default     = "us-east-1"
}
# Comment above shows intent for developers
```

### Resource Naming
Pattern: `${var.prefix}-<resource-type>` (e.g., `myco-eks`, `myco-rg`)

### Tflint Suppressions
Use `# tflint-ignore: terraform_unused_declarations` for intentionally unused variables (e.g., deprecated vars maintained for backward compatibility)

### Version Pinning
- Terraform: `>= 1.10.0`
- AWS provider: `~> 5.0`
- All providers use `~>` (pessimistic constraint) in `versions.tf`

## Storage Patterns

### Storage Types (`var.storage_type`)
- `"none"`: No shared storage
- `"standard"`: NFS server VM (`modules/aws_vm`)
- `"ha"`: EFS or FSx ONTAP (determined by `var.ontap_performance_mode` - if non-null, uses ONTAP)

Logic in `locals.tf`:
```terraform
storage_type_backend = (var.storage_type == "ha" && var.ontap_performance_mode != null) ? "ontap" 
                     : (var.storage_type == "ha") ? "efs" 
                     : "nfs"
```

### Node Pools
- Default node pool: Always created unless `create_default_nodepool=false`
- Additional pools: Defined in `node_pools` map variable
- Each pool supports custom taints, labels, VM types, disk configs (see `examples/sample-input.tfvars` lines 44-79 for CAS/compute/stateless patterns)

## Key Files Reference

- **`docs/CONFIG-VARS.md`**: Complete variable reference with tables
- **`files/policies/devops-iac-eks-policy.json`**: Required IAM permissions
- **`files/tools/iac_git_info.sh`**: Generates git hash for build info ConfigMap
- **`container-structure-test.yaml`**: Docker image validation tests
- **`.terraform.lock.hcl`**: Provider version lock (auto-generated, commit to repo)

## Common Pitfalls

1. **Ubuntu ephemeral mount**: Ubuntu 20.04 uses `/mnt` as ephemeral - cannot use for `jump_rwx_filestore_path`
2. **EBS CSI driver**: External deployments must install EBS CSI driver; use `ebs.csi.eks.amazonaws.com` provisioner (or `ebs.csi.aws.com` if EKS Auto Mode disabled)
3. **Subnet tagging**: Public subnets need `kubernetes.io/role/elb=1`, private subnets need `kubernetes.io/role/internal-elb=1` (see `main.tf` lines 91-92)
4. **Deprecated credentials**: `aws_shared_credentials_file` (singular) is deprecated; use `aws_shared_credentials_files` (list)

## Output Files

- **Kubeconfig**: Written to `[prefix]-eks-kubeconfig.conf` in working directory
- **Terraform state**: `terraform.tfstate` (local) or remote backend (if configured)
- **Build info**: `sas-iac-buildinfo` ConfigMap in `kube-system` namespace contains git hash, timestamp, tooling version
