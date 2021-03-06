# SAS Viya 4 Infrastructure as Code (IaC) for Amazon Web Services (AWS)

## Overview

This project contains Terraform scripts to provision AWS Cloud infrastructure resources required to deploy SAS Viya 4 products. Here is a list of resources this project can create -

  >- Amazon VPC and Security Group
  >- Managed Amazon Elastic Kubernetes Service(EKS)
  >- Self-Managed Node Groups with required Labels and Taints
  >- Infrastructure to deploy SAS Viya CAS in SMP or MPP mode
  >- Amazon Elastic Block Storage (EBS) for NFS
  >- Amazon Elastic File System(EFS)
  >- Amazon Relational Database Service(RDS)

[<img src="./docs/images/viya4-iac-aws-diag.png" alt="Architecture Diagram" width="750"/>](./docs/images/viya4-iac-aws-diag.png?raw=true)

Once the cloud resources are provisioned, see the [viya4-deployment](https://github.com/sassoftware/viya4-deployment) repo to deploy SAS Viya 4 products. If you need more information on the SAS Viya 4 products refer to the official [SAS&reg; Viya&reg; 4 Operations](https://go.documentation.sas.com/?cdcId=itopscdc&cdcVersion=v_001LTS&docsetId=itopswlcm&docsetTarget=home.htm&locale=en) documentation for more details.

## Prerequisites

Operational knowledge of:

- [Terraform](https://www.terraform.io/intro/index.html)
- [Docker](https://www.docker.com/)
- [AWS](https://aws.amazon.com)
- [Kubernetes](https://kubernetes.io/docs/concepts/)

### Required

- Access to **AWS account** with a user associated with the supplied [IAM Policy](./files/policies/devops-iac-eks-policy.json)
- Subscription to [Ubuntu 20.04 LTS - Focal](https://aws.amazon.com/marketplace/pp/prodview-iftkyuwv2sjxi)
- Terraform or Docker
  
  - #### Terraform

    - [Terraform](https://www.terraform.io/downloads.html) - v1.0.0
    - [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) - v1.19.9
    - [jq](https://stedolan.github.io/jq/) - v1.6
    - [AWS CLI](https://aws.amazon.com/cli) - (optional - useful as an alternative to the AWS Web Console) - v2.1.29
  
  - #### Docker
  
    - [Docker](https://docs.docker.com/get-docker/)

## Getting Started

Ubuntu 18.04 LTS is the operating system used on the Jump/NFS servers. Ubuntu creates the `/mnt` location as an ephemeral drive and cannot be used as the root location of the `jump_rwx_filestore_path` variable.

### Clone this project

Run these commands in a Terminal session:

```bash
# clone this repo
git clone https://github.com/sassoftware/viya4-iac-aws
cd viya4-iac-aws
```

### Authenticating Terraform to access AWS

See  [Authenticating Terraform to access AWS](./docs/user/TerraformAWSAuthentication.md) for details.

### Customize Input Values

Create a file named `terraform.tfvars` to customize any input variable value documented in the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file. For starters, you can copy one of the provided sample variable definition files in [examples](./examples) folder. For more details on the variables declared refer to the [CONFIG-VARS.md](docs/CONFIG-VARS.md) file.

**NOTE:** You will need to update the `cidr_blocks` in the [variables.tf](variables.tf) file to allow traffic from your current network. Without these rules, access to the cluster will only be allowed via the AWS Console.

When using a variable definition file other than `terraform.tfvars`, see [Advanced Terraform Usage](docs/user/AdvancedTerraformUsage.md) for additional command options.

## Creating and Managaging the Cloud Resources

Create and manage the AWS cloud resources by either

- using [Terraform](docs/user/TerraformUsage.md) directly on your workstation, or
- using a [Docker container](docs/user/DockerUsage.md).

## Troubleshooting

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
