# List of valid configuration variables
Supported configuration variables are listed in the table below.  All variables can also be specified on the command line.  Values specified on the command line will override all values in configuration defaults files.

## Table of Contents

* [Required Variables](#required-variables)
* [Admin Access](#admin-access)
* [General](#general)
* [Nodepools](#nodepools)
   + [Default Nodepool](#default-nodepool)
   + [CAS Nodepool](#cas-nodepool)
   + [Compute Nodepool](#compute-nodepool)
   + [Connect Nodepool](#connect-nodepool)
   + [Stateless Nodepool](#stateless-nodepool)
   + [Stateful Nodepool](#stateful-nodepool)
* [Postgres](#postgres)

Terraform input variables can be set in the following ways:
- Individually, with the [-var command line option](https://www.terraform.io/docs/configuration/variables.html#variables-on-the-command-line).
- In [variable definitions (.tfvars) files](https://www.terraform.io/docs/configuration/variables.html#variable-definitions-tfvars-files). We recommend this way for most variables.
- As [environment variables](https://www.terraform.io/docs/configuration/variables.html#environment-variables). We recommend this way for the variables that set the [Azure authentication](#required-variables-for-azure-authentication).

## Required Variables

| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: | 
| prefix | A prefix used in the name of all the AWS resources created by this script. | string | | The prefix string must start with a lowercase letter and contain only alphanumeric characters and dashes (-), but cannot end with a dash. |
| location | The AWS Region to provision all resources in this script | string | "us-east-1" | |

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
| create_default_nodepool | Create default node pool | bool | true ||
| default_nodepool_vm_type | Type of the default nodepool VMs | string | "m5.2xlarge" | |
| default_nodepool_os_disk_type | Disk type for default nodepool | string | gp2 ||
| default_nodepool_os_disk_size | Disk size for default nodepool VMs in GB | number | 200 ||
| default_nodepool_initial_node_count | Number of initial nodes in the default nodepool | number | 1 | The value must be between `default_nodepool_min_nodes` and `default_nodepool_max_nodes`|
| default_nodepool_max_nodes | Maximum number of nodes for the default nodepool | number | 5 | |
| default_nodepool_min_nodes | Minimum number of nodes for the default nodepool | number | 1 | |
| default_nodepool_taints | Taints for the default nodepool VMs | list of strings | | |
| default_nodepool_labels | Labels to add to the dfeault nodepool VMs | map | | |

### CAS Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_cas_nodepool | Create CAS nodepool | bool | true | |
| cas_nodepool_vm_type | Type of the CAS nodepool VMs | string | "m5.8xlarge" | |
| cas_nodepool_os_disk_type | Disk type for CAS nodepool | string | gp2 ||
| cas_nodepool_os_disk_size | Disk size for CAS nodepool VMs in GB | number | 200 | |
| cas_nodepool_initial_node_count| Initial number of CAS nodepool VMs | number | 1 | The value must be between `cas_nodepool_min_nodes` and `cas_nodepool_max_nodes` |
| cas_nodepool_max_nodes | Maximum number of nodes for the CAS nodepool | number | 5 | |
| cas_nodepool_min_nodes | Minimum number of nodes for the CAS nodepool | number | 1 | |
| cas_nodepool_taints | Taints for the CAS nodepool VMs | list of strings | ["workload.sas.com/class=cas:NoSchedule"] | |
| cas_nodepool_labels | Labels to add to the CAS nodepool VMs | map | {"workload.sas.com/class" = "cas"} | |
### Compute Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_compute_nodepool | Create Compute nodepool | bool | true | false | |
| compute_nodepool_vm_type | Type of the Compute nodepool VMs | string | "m5.8xlarge" | |
| compute_nodepool_os_disk_type | Disk type for Compute nodepool | string | gp2 ||
| compute_nodepool_os_disk_size | Disk size for Compute nodepool VMs in GB | number | 200 | |
| compute_nodepool_initial_node_count| Initial number of Compute nodepool VMs | number | 1 | The value must be between `compute_nodepool_min_nodes` and `compute_nodepool_max_nodes` |
| compute_nodepool_max_nodes | Maximum number of nodes for the Compute nodepool | number | 5 | |
| compute_nodepool_min_nodes | Minimum number of nodes for the Compute nodepool | number | 1 | |
| compute_nodepool_taints | Taints for the Compute nodepool VMs | list of strings | ["workload.sas.com/class=connect:NoSchedule"] | |
| compute_nodepool_labels | Labels to add to the Compute nodepool VMs | map | {"workload.sas.com/class" = "connect"  "launcher.sas.com/prepullImage" = "sas-programming-environment" }  | |
### Connect Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_connect_nodepool | Create Connect nodepool | bool | true | false | |
| connect_nodepool_vm_type | Type of the Connect nodepool VMs | string | "m5.8xlarge" | |
| connect_nodepool_os_disk_type | Disk type for Connect nodepool | string | gp2 ||
| connect_nodepool_os_disk_size | Disk size for Connect nodepool VMs in GB | number | 200 | |
| connect_nodepool_initial_node_count| Initial number of Connect nodepool VMs | number | 1 | The value must be between `connect_nodepool_min_nodes` and `connect_nodepool_max_nodes` |
| connect_nodepool_max_nodes | Maximum number of nodes for the Connect nodepool | number | 5 | |
| connect_nodepool_min_nodes | Minimum number of nodes for the Connect nodepool | number | 1 | |
| connect_nodepool_taints | Taints for the Connect nodepool VMs | list of strings | ["workload.sas.com/class=compute:NoSchedule"] | |
| connect_nodepool_labels | Labels to add to the Connect nodepool VMs | map | {"workload.sas.com/class" = "compute"  "launcher.sas.com/prepullImage" = "sas-programming-environment" }  | |
### Stateless Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateless_nodepool | Create Stateless nodepool | bool | true | |
| stateless_nodepool_vm_type | Type of the Stateless nodepool VMs | string | "m5.4xlarge" | |
| stateless_nodepool_os_disk_type | Disk type for Stateless nodepool | string | gp2 ||
| stateless_nodepool_os_disk_size | Disk size for Stateless nodepool VMs in GB | number | 200 | |
| stateless_nodepool_initial_node_count| Initial number of Stateless nodepool VMs | number | 1 | The value must be  between `stateless_nodepool_min_nodes` and `stateless_nodepool_max_nodes`
| stateless_nodepool_max_nodes | Maximum number of nodes for the Stateless nodepool | number | 5 | |
| stateless_nodepool_min_nodes | Minimum number of nodes for the Stateless nodepool | number | 1 | |
| stateless_nodepool_taints | Taints for the Stateless nodepool VMs | list of strings | ["workload.sas.com/class=stateless:NoSchedule"] | |
| stateless_nodepool_labels | Labels to add to the Stateless nodepool VMs | map | {"workload.sas.com/class" = "stateless" } | |
### Stateful Nodepool
| Name | Description | Type | Default | Notes |
| :--- | ---: | ---: | ---: | ---: |
| create_stateful_nodepool | Create Stateful nodepool | bool | true | |
| stateful_nodepool_vm_type | Type of the Stateful nodepool VMs | string | "m5.2xlarge" | |
| stateful_nodepool_os_disk_type | Disk type for Stateful nodepool | string | gp2 ||
| stateful_nodepool_os_disk_size | Disk size for Stateful nodepool VMs in GB | number | 200 | |
| stateful_nodepool_initial_node_count| Number of initial Stateful nodepool VMs | number | 1 | The value must be  between `stateful_nodepool_min_nodes` and `stateful_nodepool_max_nodes`|
| stateful_nodepool_max_nodes | Maximum number of nodes for the Stateful nodepool | number | 3 | |
| stateful_nodepool_min_nodes | Minimum number of nodes for the Stateful nodepool | number | 1 | |
| stateful_nodepool_taints | Taints for the Stateful nodepool VMs | list of strings | ["workload.sas.com/class=stateful:NoSchedule"] | |
| stateful_nodepool_labels | Labels to add to the Stateful nodepool VMs | map | {"workload.sas.com/class" = "stateful" }  | |


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




