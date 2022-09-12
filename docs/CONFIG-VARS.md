# Valid Configuration Variables

Supported configuration variables are listed in the tables below.  All variables can also be specified on the command line.  Values specified on the command line will override values in configuration defaults files.

## Table of Contents

- [Valid Configuration Variables](#valid-configuration-variables)
  - [Table of Contents](#table-of-contents)
  - [Required Variables](#required-variables)
    - [AWS Authentication](#aws-authentication)
      - [Using Static Credentials](#using-static-credentials)
      - [Using AWS Profile](#using-aws-profile)
  - [Admin Access](#admin-access)
  - [Networking](#networking)
    - [Use Existing](#use-existing)
  - [IAM](#iam)
  - [General](#general)
  - [Node Pools](#node-pools)
    - [Default Node Pool](#default-node-pool)
    - [Additional Node Pools](#additional-node-pools)
  - [Storage](#storage)
    - [NFS Server](#nfs-server)
    - [AWS Elastic File System (EFS)](#aws-elastic-file-system-efs)
  - [PostgreSQL Server](#postgresql-server)

Terraform input variables can be set in the following ways:

- Individually, with the [`-var` command-line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).

- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). SAS recommends this method for setting most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). SAS recommends this method for setting the variables that enable [AWS authentication](#aws-authentication).

## Required Variables

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| prefix | A prefix used in the name of all the AWS resources created by this script | string | | The prefix string must start with a lowercase letter and can contain only lowercase alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The AWS Region with which to provision all resources in this script | string | "us-east-1" | |

### AWS Authentication

The Terraform process manages AWS resources on your behalf. In order to do so, it needs the credentials for an AWS identity with the required permissons.

You can use either static credentials or the name of an AWS profile. If both are specified, the static credentials take precedence. For recommendations on how to set these variables in your environment, see [Authenticating Terraform to Access AWS](./user/TerraformAWSAuthentication.md).

#### Using Static Credentials

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| aws_access_key_id | Static credential key | string | "" | |
| aws_secret_access_key | Static credential secret | string | "" | |
| aws_session_token | Session token for validating temporary AWS credentials | string | "" | Required only when using temporary AWS credentials. |

#### Using AWS Profile

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| aws_profile | Name of AWS Profile in the credentials file | string | "" | |
| aws_shared_credentials_file | Path to credentials file | string | [`~/.aws/credentials` on Linux and macOS](https://docs.aws.amazon.com/credref/latest/refdocs/file-location.html) | Can be ignored when using the default value. |

## Admin Access

By default, the pubic endpoints of the AWS resources that are being created are only accessible through authenticated AWS clients (for example, the AWS Portal, the AWS CLI, etc.).
To enable access for other administrative client applications (for example `kubectl`, `psql`, etc.), you can set Security Group rules to control access from your source IP addresses.

To set these permissions as part of this Terraform script, specify ranges of IP addresses in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing). Contact your Network Administrator to find the public CIDR range of your network.

NOTE: When deploying infrastructure into a private network (e.g. a VPN), with no public endpoints, the options documented in this block are not applicable.

NOTE: The script will either create a new Security Group, or use an existing Security Group, if specified in the `security_group_id` variable.

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use an empty list [] to disallow access explicitly.

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| default_public_access_cidrs | IP address ranges that are allowed to access all created cloud resources | list of strings | | Set a default for all resources. |
| cluster_endpoint_public_access_cidrs | IP address ranges that are allowed to access the AKS cluster API | list of strings | | For client admin access to the cluster api (by kubectl, for example). Only used with `cluster_api_mode=public` |
| vm_public_access_cidrs | IP address ranges that are allowed to access the VMs | list of strings | | Opens port 22 for SSH access to the jump server and/or NFS VM by adding Ingress Rule on the Security Group. Only used with `create_jump_public_ip=true` or `create_nfs_public_ip=true`. |
| postgres_access_cidrs | IP address ranges that are allowed to access the AWS PostgreSQL server | list of strings ||	Opens port 5432 by adding Ingress Rule on the Security Group. Only used when creating postgres instances.|

## Networking
 | Name | Description | Type | Default | Notes |
 | :--- | ---: | ---: | ---: | ---: |
 | vpc_cidr | Address space for the VPC | string | "192.168.0.0/16" | This variable is ignored when `vpc_id` is set (AKA bring your own VPC). |
 | subnets | Subnets to be created and their settings | map | See below for default values | This variable is ignored when `subnet_ids` is set (AKA bring your own subnets). All defined subnets must exist within the VPC address space. |

The default values for the subnets variable are as follows:

```yaml
{
  "private" : ["192.168.0.0/18", "192.168.64.0/18"],
  "public" : ["192.168.129.0/25", "192.168.129.128/25"],
  "database" : ["192.168.128.0/25", "192.168.128.128/25"]
}
```

### Use Existing
If desired, you can deploy into an existing VPC, subnet and NAT gateway, and Security Group.

**Note**: All existing VPC/subnet resources must be in the same AWS region as the [location](./CONFIG-VARS.md#required-variables) you specify.

The variables in the table below can be used to define the existing resources. Refer to the [Bring Your Own Network](./user/BYOnetwork.md) page for information about all supported scenarios for using existing network resources, with additional details and requirements.


| Name | Description | Type | Default | Notes |
 | :--- | ---: | ---: | ---: | ---: |
 | vpc_id | ID of existing VPC | string | null | Only required if deploying into existing VPC. |
 | subnet_ids | List of existing subnets mapped to desired usage | map(string) | {} | Only required if deploying into existing subnets. |
 | nat_id | ID of existing AWS NAT gateway | string | null | Only required if deploying into existing VPC and subnets. |
 | security_group_id | ID of existing Security Group that controls external access to Jump/NFS VMs and Postgres | string | null | Only required if using existing Security Group. See [Security Group](./user/BYOnetwork.md#external-access-security-group) for requirements. |
| cluster_security_group_id | ID of existing Security Group that controls Pod access to the control plane | string | null | Only required if using existing Cluster Security Group. See [Cluster Security Group](./user/BYOnetwork.md#cluster-security-group) for requirements.|
| workers_security_group_id | ID of existing Security Group that allows access between node VMs, Jump VM, and data sourcess (nfs, efs, postges) | string | null | Only required if using existing Security Group for Node Group VMs. See [Workers Security Group](./user/BYOnetwork.md#workers-security-group) for requirements. |

Example `subnet_ids` variable:

```yaml
subnet_ids = {
  "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  "private" : ["existing-private-subnet-id1", "existing-private-subnet-id2"],
  "database" : ["existing-database-subnet-id1","existing-database-subnet-id2"]
}
```

## IAM

By default, two custom IAM policies and two custom IAM roles (with instance profiles) are created. If your site security protocol does not allow for automatic creation of IAM resources, you can provide pre-created roles using the following options:

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| cluster_iam_role_name | Name of existing IAM role for the EKS cluster | string | "" | |
| workers_iam_role_name | Name of existing IAM role for the cluster node VMs | string | "" | |

The cluster IAM role must include three AWS-managed policies and one custom policy.

AWS-managed policies:

- `AmazonEKSClusterPolicy`
- `AmazonEKSServicePolicy`
- `AmazonEKSVPCResourceController`

Custom policy:

```yaml
 "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInternetGateways",
                "ec2:DescribeAddresses",
                "ec2:DescribeAccountAttributes"
            ],
            "Resource": "*"
        }
    ]
```

The Workers IAM role must include the following three AWS-managed policies and one custom policy. It also requires an instance profile with the same name as the role.

AWS-managed policies:

- `AmazonEKSWorkerNodePolicy`
- `AmazonEKS_CNI_Policy`
- `AmazonEC2ContainerRegistryReadOnly`

Custom policy:

```yaml
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "elasticfilesystem:DescribeFileSystems",
        "iam:DeletePolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
```

## General

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| create_static_kubeconfig | Allows the user to create a provider- or service account-based kubeconfig file | bool | false | A value of `false` defaults to using the cloud provider's mechanism for generating the kubeconfig file. A value of `true` creates a static kubeconfig that uses a service account and cluster role binding to provide credentials. |
| kubernetes_version | The EKS cluster Kubernetes version | string | "1.22" | |
| create_jump_vm | Create bastion host (jump VM) | bool | true| |
| create_jump_public_ip | Add public IP address to jump VM | bool | true | |
| jump_vm_admin | OS admin user for the jump VM | string | "jumpuser" | |
| jump_rwx_filestore_path | File store mount point on jump VM | string | "/viya-share" | This location cannot include "/mnt" as its root location. This disk is ephemeral on Ubuntu, which is the operating system being used for the jump VM and NFS servers. |
| tags | Map of common tags to be placed on all AWS resources created by this script | map | { project_name = "viya" } | |
| autoscaling_enabled | Enable cluster autoscaling | bool | true | |
| ssh_public_key | File name of public ssh key for jump and nfs VM | string | "~/.ssh/id_rsa.pub" | Required with `create_jump_vm=true` or `storage_type=standard` |
| cluster_api_mode | Public or private IP for the cluster api| string|"public"|Valid Values: "public", "private" |

## Node Pools

### Default Node Pool

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| default_nodepool_vm_type | Type of the default node pool VMs | string | "m5.2xlarge" | |
| default_nodepool_os_disk_type | Disk type for default node pool VMs | string | gp2 | |
| default_nodepool_os_disk_size | Disk size for default node pool VMs in GB | number | 200 ||
| default_nodepool_os_disk_iops | Disk IOPS for default node pool VMs | number | | For `io1`, you MUST set the value to your desired IOPS value. Refer to [Amazon EBS volume types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) for details on values based on the `default_nodepool_os_disk_type` selected.|
| default_nodepool_node_count | Initial number of nodes in the default node pool | number | 1 | The value must be between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`. |
| default_nodepool_max_nodes | Maximum number of nodes in the default node pool | number | 5 | |
| default_nodepool_min_nodes | Minimum and initial number of nodes for the node pool | number | 1 | |
| default_nodepool_taints | Taints for the default node pool VMs | list of strings | | |
| default_nodepool_labels | Labels to add to the default node pool VMs | map | | |
| default_nodepool_custom_data | Additional user data that will be appended to the default user data. | string | "" | The value must be an empty string ("") or the path to a file containing a Bash script snippet that will be executed on the node pool. |
| default_nodepool_metadata_http_endpoint | The state of the default node pool's metadata service | string | "enabled" | Valid values are: enabled, disabled. |
| default_nodepool_metadata_http_tokens | The state of the session tokens for the default node pool | string | "required" | Valid values are: required, optional. |
| default_nodepool_metadata_http_put_response_hop_limit | The desired HTTP PUT response hop limit for instance metadata requests for the default node pool | number | 1 | Valid values are either null or any number greater than 0. |

### Additional Node Pools

Additional node pools can be created separately from the default node pool. This is done with the `node_pools` variable, which is a map of objects. Each node pool requires the following variables:

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| vm_type | Type of the node pool VMs | string | | https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html |
| cpu_type | Processor type CPU/GPU | string | AL2_x86_64| [AMI type](https://docs.aws.amazon.com/eks/latest/APIReference/API_Nodegroup.html#AmazonEKS-Type-Nodegroup-amiType) – Choose Amazon Linux 2 (AL2_x86_64) for Linux non-GPU instances, Amazon Linux 2 GPU Enabled (AL2_x86_64_GPU) for Linux GPU instances|
| os_disk_type | Disk type for node pool VMs | string | | `gp2` or `io1` |
| os_disk_size | Disk size for node pool VMs in GB | number | | |
| os_disk_iops | Amount of provisioned [IOPS](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-io-characteristics.html) | number | | For `io1`, you MUST set the value to your desired IOPS value. Reference [Amazon EBS volume types](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-volume-types.html) for details on values based on the `os_disk_type` selected.|
| min_nodes | Minimum number of nodes in the node pool | number | | The value must be between `min_nodes` and `max_nodes`. |
| max_nodes | Maximum number of nodes in the node pool | number | | The value must be between `min_nodes` and `max_nodes`. |
| node_taints | Taints for the node pool VMs | list of strings | | |
| node_labels | Labels to add to the node pool VMs | map | | On nodes where you want to run SAS Pods, include this label: `"workload.sas.com/node"  = ""`. |
| custom_data | Additional user data that will be appended to the default user data | string | | The value must be an empty string ("") or the path to a file containing a Bash script snippet that will be executed on the node pool. |
| metadata_http_endpoint | The state of the node pool's metadata service | string | "enabled" | Valid values are: enabled, disabled. |
| metadata_http_tokens | The state of the session tokens for the node pool | string | "required" | Valid values are: required, optional. |
| metadata_http_put_response_hop_limit | The desired HTTP PUT response hop limit for instance metadata requests for the node pool | number | 1 | Valid values are any number greater than 0. |

## Storage

| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| storage_type | Type of Storage. Valid Values: "standard", "ha"  | string | "standard" | A value of "standard" creates NFS server VM; a value of "ha" creates an AWS EFS mountpoint. |

### NFS Server

When `storage_type=standard`, an NFS server VM is created, and the following variables are applicable:

<!--| Name | Description | Type | Default | Notes | -->
| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| create_nfs_public_ip | Add public IP address to the NFS server VM | bool | false |  |
| nfs_vm_admin | Admin user account for the NFS server VM | string | "nfsuser" | |
| nfs_raid_disk_size | Size in GiB for each EBS volume of the RAID0 cluster on the NFS server VM | number | 128 | |
| nfs_raid_disk_type | Disk type for the NFS server EBS volumes | string | "gp2" | Valid values are: "standard", "gp2", "io1", "io2", "sc1" or "st1". |
| nfs_raid_disk_iops | IOPS for the the NFS server EBS volumes | number | 0 | Only used when `nfs_raid_disk_type` is "io1" or "io2". |

### AWS Elastic File System (EFS)

When `storage_type=ha`, the [AWS Elastic File System](https://aws.amazon.com/efs/) service is created, and the following variables are applicable:

<!--| Name | Description | Type | Default | Notes | -->
| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| efs_performance_mode | EFS performance mode | string | generalPurpose | Supported values are `generalPurpose` or `maxIO` |

## PostgreSQL Server

When setting up ***external database servers***, you must provide information about those servers in the `postgres_servers` variable block. Each entry in the variable block represents a ***single database server***.

This code only configures database servers. No databases are created during the infrastructure setup.

The variable has the following format:

```terraform
postgres_servers = {
  default = {},
  ...
}
```


**NOTE**: The `default = {}` elements is always required when creating external databases. This is the systems default database server.

Each server element, like `foo = {}`, can contain none, some, or all of the parameters listed below:

<!--| Name | Description | Type | Default | Notes | -->
| <div style="width:50px">Name</div> | <div style="width:150px">Description</div> | <div style="width:50px">Type</div> | <div style="width:75px">Default</div> | <div style="width:150px">Notes</div> |
| :--- | :--- | :--- | :--- | :--- |
| server_version | The version of the PostgreSQL server | string | "11" | Changing this value trigger resource recreation |
| instance_type | The VM type for the PostgreSQL Server | string | "db.m5.xlarge" | |
| storage_size | Max storage allowed for the PostgreSQL server in MB | number | 50 |  |
| backup_retention_days | Backup retention days for the PostgreSQL server | number | 7 | Supported values are between 7 and 35 days. |
| storage_encrypted | Encrypt PostgreSQL data at rest | bool | false| |
| administrator_login | The Administrator Login for the PostgreSQL Server | string | "pgadmin" | The admin login name can not be 'admin', must start with a letter, and must be between 1-16 characters in length, and can only contain underscores, letters, and numbers. Changing this forces a new resource to be created |
| administrator_password | The Password associated with the administrator_login for the PostgreSQL Server | string | "my$up3rS3cretPassw0rd" | The admin passsword must have more than 8 characters, and be composed of any printable characters except the following / ' \" @ characters. |
| multi_az | Specifies if PostgreSQL instance is multi-AZ | bool | false | |
| deletion_protection | Protect from accidental resource deletion | bool | false | |
| ssl_enforcement_enabled | Enforce SSL on connections to PostgreSQL server instance | bool | true | |
| parameters | additional parameters for PostgreSQL server | list(map(string)) | [] | More details can be found [here](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Appendix.PostgreSQL.CommonDBATasks.html#Appendix.PostgreSQL.CommonDBATasks.Parameters) |
| options | additional options for PostgreSQL server | any | [] | |


Here is a sample of the `postgres_servers` variable with the `default` entry only overriding the `administrator_password` parameter and the `cps` entry overriding all of the parameters:

```terraform
database_servers = {
  default = {
    administrator_password       = "D0ntL00kTh1sWay"
  },
  another_server = {
    instance_type                = "db.m5.xlarge"
    storage_size                 = 50
    storage_encrypted            = false
    backup_retention_days        = 7
    multi_az                     = false
    deletion_protection          = false
    administrator_login          = "cpsadmin"
    administrator_password       = "1tsAB3aut1fulDay"
    server_version               = "12"
    server_port                  = "5432"
    ssl_enforcement_enabled      = true
    parameters                   = [{ "apply_method": "immediate", "name": "foo" "value": "true" }, { "apply_method": "immediate", "name": "bar" "value": "false" }]
    options                      = []
  }
}
```
