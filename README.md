# SAS Viya 4 Infrastructure a Code(IAC) for Amazon Web Services(AWS)

## Overview

This project contains Terraform scripts to provision AWS Cloud infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create -

  >- Amazon VPC and Security Group
  >- Managed Amazon Elastic Kubernetes Service(EKS)
  >- Managed Node Groups with required Labels and Taints
  >- Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  >- Amazon Elastic File System(EFS)
  >- Amazon Relational Database Service(RDS)

## Prerequisites

Operational knowledge of [Terraform](https://www.terraform.io/intro/index.html), [AWS](https://aws.amazon.com), and [Kubernetes](https://kubernetes.io/docs/concepts/).
This project can be run either with Terraform installed on your local machine or with a Docker image that can be built using the included [Dockerfile](Dockerfile).

### Required

- [Terraform v0.13.3](https://www.terraform.io/downloads.html) or [Docker](https://docs.docker.com/get-docker/)
- Access to **AWS account**

### Optional

- [AWS CLI v2.0](https://aws.amazon.com/cli) comes in handy as an alternative to the AWS Web Console

## Getting Started

Run these commands in a Terminal session

### Clone this project

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-iac-aws
cd viya4-iac-aws
```

### !!!!! TODO: Fix this subsection !!!!! Authenticating Terraform to access AWS

Export these environment variables values, see [Authenticating Terraform to access AWS](./docs/user/TerraformAWSAuthentication.md) for details or simply refer to [Terraform documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

```bash
# export needed IDs and Secrets
export TF_VAR_subscription_id="SUBSCRIPTION_ID"
export TF_VAR_tenant_id="TENANT_ID"
export TF_VAR_client_id="SP_APPID"
export TF_VAR_client_secret="SP_PASSWD"
```

### Customize Input Values

Create a file named `terraform.tfvars` to customize any input variable value. For starters, you can copy one of the provided sample variable definition files in [examples](./examples) folder. For more details on the variables declared in [variables.tf](variables.tf) refer to [CONFIG-VARS.md](docs/CONFIG-VARS.md).

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

### Running Terraform Commands

Initialize the Terraform environment for this project by running 

```bash
terraform init
```

This creates a `.terraform` directory locally and initializes Terraform plugins/modules used in this project.

**Note:** `terraform init` only needs to be run once unless new Terraform plugins/modules were added.

To preview the resources that the Terraform script will create, optionally run

```bash
terraform plan
```

When satisfied with the plan and ready to create cloud resources, run

```bash
terraform apply
```

`terraform apply` can take a few minutes to complete. Once complete, output values are written to the console. These output values can be displayed late by again running

```bash
terraform output
```

### Modifying Cloud Resources

After provisioning the infrastructure if further changes were to be made then add the variable and desired value to terraform.tfvars and run `terrafom apply` again.

### Interacting with Kubernetes cluster

Terraform script writes `kube_config` output value to a file `./[prefix]-eks-kubeconfig.conf`. Now that you have your Kubernetes cluster up and running, here's how to connect to the cluster

```bash
export KUBECONFIG=./[prefix]-aks-kubeconfig.conf
kubectl get nodes
```

**Note** this requires `cluster_endpoint_public_access_cidrs` value to be set.

### Examples

We include several samples - `sample-input*.tfvars` in [examples](./examples) folder to get started. Evaluate the sample files, then review the [CONFIG-VARS.md](docs/CONFIG-VARS.md) to see any other variables can be customized for your needs.

### Troubleshooting

See [troubleshooting](./docs/Troubleshooting.md) page for help with some frequently found issues.

## Contributing

> We welcome your contributions! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to submit contributions to this project. 

## License

> This project is licensed under the [Apache 2.0 License](LICENSE).

## Additional Resources

### AWS

- Installing AWS CLI v2 - https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html
- AWS EKS intro - https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html


### Terraform 

- AWS Provider - https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- AWS EKS - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster
