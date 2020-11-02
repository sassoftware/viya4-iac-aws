# List of valid configuration variables

Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

* [Required Variables](#required-variables)
* [AWS Authentication](#aws-authentication)
  * [Static Credentials](#using-static-credentials)
  * [AWS Profile](#using-aws-profile)
* [Admin Access](#admin-access)
* [General](#general)
* [Nodepools](#nodepools)
  * [Default Nodepool](#default-nodepool)
  * [Additional Nodepools](#additional-nodepools)

* [Postgres](#postgres)

Terraform input variables can be set in the following ways:

* Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).

* In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
* As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend this way for the variables that set the [AWS authentication](#aws-authentication).

## Required Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| prefix | A prefix used in the name of all the AWS resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The AWS Region to provision all resources in this script | string | "us-east-1" | |

## AWS Authentication

The Terraform process manages AWS resources on your behalf. In order to do so, it needs to know the credentials for an AWS identity with the required permissons.

You can use either static credentials, or the name of an AWS Profile. If both are specified, the static credentials will take precedence.

### Using Static Credentials

| Terraform Variable | Alternative AWS Environment Variable | Description |
| :--- | :--- | :--- |
| `aws_access_key_id` | `AWS_ACCESS_KEY_ID` | static credential key |
| `aws_secret_access_key` | `AWS_SECRET_ACCESS_KEY` | static credential secret |
| `aws_session_token` | `AWS_SESSION_TOKEN` | session token for validating temporary credentials |

### Using AWS Profile

| Terraform Variable | Alternative AWS Environment Variable | Description |
| :--- | :--- | :--- |
| `aws_profile` | `AWS_PROFILE` | name of AWS Profile in the credentials file |
| `aws_shared_credentials_file` | `AWS_SHARED_CREDENTIALS_FILE` | location of credentials file. Default is `$HOME/.aws/credentials` on Linux and macOS, and `"%USERPROFILE%\.aws\credentials"` on Windows |

Find more on authenticating Terraform under [Authenticating Terraform to access AWS](./user/TerraformAWSAuthentication).

## Admin Access

By default, the API of the AWS resources that are being created are only accessible through authenticated AWS clients (e.g. the AWS Portal, the `aws` CLI, etc.)
To allow access for other administrative client applications (for example `kubectl`, `psql`, etc.), you want to open up the Azure firewall to allow access from your source IPs.
To do this, specify ranges of IP in [CIDR notation](https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing).
Contact your Network System Administrator to find the public CIDR range of your network.

You can use `default_public_access_cidrs` to set a default range for all created resources. To set different ranges for other resources, define the appropriate variable. Use and empty list `[]` to disallow access explicitly.

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_public_access_cidrs | IP Ranges allowed to access all created cloud resources | list of strings | | Use to to set a default for all Resources |
| cluster_endpoint_public_access_cidrs | IP Ranges allowed to access the AKS cluster api | list of strings | | for client admin access to the cluster, e.g. with `kubectl` |
| vm_public_access_cidrs | IP Ranges allowed to access the VMs | list of strings | | opens port 22 for SSH access to the jump and/or nfs VM |
| postgres_access_cidrs | IP Ranges allowed to access the Azure PostgreSQL Server | list of strings |||

## General

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| kubernetes_version | The EKS cluster K8S version | string | "1.17" | |
| ssh_public_key | Public ssh key for VMs | string | | |
| create_jump_vm | Create bastion host | bool | true| |
| create_jump_public_ip | Add public ip to jump VM | bool | true | |
| jump_vm_admin | OS Admin User for the Jump VM | string | "jumpuser" | |
| tags | Map of common tags to be placed on all AWS resources created by this script | map | { project_name = "viya" } | |

## Nodepools

### Default Nodepool

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "m5.2xlarge" | |
| default_nodepool_os_disk_type | Disk type for default nodepool | string | gp2 ||
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 200 ||
| default_nodepool_node_count | Number of initial nodes in the default nodepool | number | 1 | The value must be between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`|
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepool | number | 5 | |
| default_nodepool_min_nodes | Minimum and initial number of nodes for the nodepool | number | 1 | |
| default_nodepool_taints | Taints for the default nodepool VMs | list of strings | | |
| default_nodepool_labels | Labels to add to the dfeault nodepool VMs | map | | |

### Additional Nodepools

Additional node pools can be created separate from the default nodepool. This is done with the `node_pools` variable which is a map of objects. Each nodepool requires the following variables:

| Name | Description | Type | Notes |
| :--- | ---: | ---: | ---: |
| vm_type | Type of the nodepool VMs | string | |
| os_disk_size | Disk size for nodepool VMs in GB | number | |
| min_nodes | Minimum number of nodes for the nodepool | number | The value must be between `min_nodes` and `max_nodes`|
| max_nodes | Maximum number of nodes for the nodepool | number | The value must be between `min_nodes` and `max_nodes`|
| node_taints | Taints for the nodepool VMs | list of strings | |
| node_labels | Labels to add to the nodepool VMs | map | |

## Postgres

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_postgres | Create an AWS Postgres DB (RDS) server instance | bool | false | |
| postgres_server_name | Name of PostgreSQL server | string | "" | Changing this value trigger resource recreation |
| postgres_server_version | The version of the PostgreSQL server | string | "11" | Changing this value trigger resource recreation |
| postgres_instance_type | The VM type for the PostgreSQL Server | string | "db.m5.xlarge" | |
| postgres_storage_size | Max storage allowed for the PostgreSQL server in MV | number | 50 |  |
| postgres_backup_retention_days | Backup retention days for the PostgreSQL server | number | 7 | Supported values are between 7 and 35 days. |
| postgres_storage_encrypted | Encrypt PostgrSQL data at rest | bool | false| |
| postgres_administrator_login | The Administrator Login for the PostgreSQL Server | string | "pgadmin" | Changing this forces a new resource to be created |
| postgres_administrator_password | The Password associated with the postgres_administrator_login for the PostgreSQL Server | string | | |
| postgres_db_name | Name of database to create | string | "SharedServices" | |
| postgres_deletion_protection | Protect from accidental resource deletion | bool | false | |
| postgres_parameters | additional parameters for PostgreSQL server | list of maps | [] | |
| postgres_options | additional options for PostgreSQL server | list of maps | [] |   |
