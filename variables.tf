# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## Global
# The prefix used for naming all cloud resources. Must start with a lowercase letter and can only contain lowercase letters, numbers, and hyphens (not starting or ending with '-').
variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with a lowercase letter and contain only alphanumeric characters and hyphens or dashes (-), but cannot start or end with '-'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, hyphens, or dashes (-), but cannot start or end with '-'."
  }
}

## Provider
# AWS region where all resources will be provisioned. Default is 'us-east-1'.
variable "location" {
  description = "AWS Region to provision all resources in this script."
  type        = string
  default     = "us-east-1"
}

# AWS CLI profile name to use for authentication. If empty, the default profile is used.
variable "aws_profile" {
  description = "Name of Profile in the credentials file."
  type        = string
  default     = ""
}

# Path to the AWS credentials file if not using the default location. Useful for custom setups.
variable "aws_shared_credentials_file" {
  description = "Name of credentials file, if using non-default location."
  type        = string
  default     = ""
}

# List of paths to shared credentials files. Allows specifying multiple credentials files for advanced use cases.
variable "aws_shared_credentials_files" {
  description = "List of paths to shared credentials files, if using non-default location."
  type        = list(string)
  default     = null
}

# AWS session token for temporary credentials, typically used with MFA or assumed roles.
variable "aws_session_token" {
  description = "Session token for temporary credentials."
  type        = string
  default     = ""
}

# AWS access key ID for static credentials. Used for programmatic access.
variable "aws_access_key_id" {
  description = "Static credential key."
  type        = string
  default     = ""
}

# AWS secret access key for static credentials. Used for programmatic access.
variable "aws_secret_access_key" {
  description = "Static credential secret."
  type        = string
  default     = ""
}

# Identifier for the infrastructure-as-code tooling used. Default is 'terraform'.
variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this provider's infrastructure."
  type        = string
  default     = "terraform"
}

## Public & Private Access
# List of CIDR blocks allowed public access to created resources (e.g., VMs, endpoints).
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources - Public."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed private access to created resources.
variable "default_private_access_cidrs" {
  description = "List of CIDRs to access created resources - Private."
  type        = list(string)
  default     = null
}

# List of EKS cluster log types to enable in CloudWatch (e.g., audit, api, authenticator).
variable "cluster_enabled_log_types" {
  description = "List of audits to record from EKS cluster in CloudWatch"
  type        = list(string)
  default     = null
  # Example value: ["audit","api","authenticator"] 
}

# List of CIDR blocks allowed public access to the Kubernetes cluster endpoint.
variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Public."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed private access to the Kubernetes cluster endpoint.
variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Private."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed private access to VPC endpoints.
variable "vpc_endpoint_private_access_cidrs" {
  description = "List of CIDRs to access VPC endpoints - Private."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed public access to jump or NFS VMs.
variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump VM or NFS VM - Public."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed private access to jump or NFS VMs.
variable "vm_private_access_cidrs" {
  description = "List of CIDRs to access jump VM or NFS VM - Private."
  type        = list(string)
  default     = null
}

# List of CIDR blocks allowed access to the PostgreSQL server.
variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server."
  type        = list(string)
  default     = null
}

## Provider Specific
# SSH public key path used for VM access. Default is '~/.ssh/id_rsa.pub'.
variable "ssh_public_key" {
  description = "SSH public key used to access VMs."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# EFS (Elastic File System) performance mode. Can be 'generalPurpose' or 'maxIO'.
variable "efs_performance_mode" {
  description = "EFS performance mode. Supported values are `generalPurpose` or `maxIO`."
  type        = string
  default     = "generalPurpose"
}

# EFS throughput mode. 'bursting' for automatic scaling, 'provisioned' for fixed throughput (requires 'efs_throughput_rate').
variable "efs_throughput_mode" {
  description = "EFS throughput mode. Supported values are 'bursting' and 'provisioned'. When using 'provisioned', 'efs_throughput_rate' is required."
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], lower(var.efs_throughput_mode))
    error_message = "ERROR: Supported values for `efs_throughput_mode` are - bursting, provisioned."
  }
}

# EFS throughput rate in MiB/s. Only used if 'efs_throughput_mode' is 'provisioned'. Must be between 1 and 1024.
variable "efs_throughput_rate" {
  description = "EFS throughput rate, measured in MiB/s. Valid values range from 1 to 1024 - MiB/s. Only applicable with 'efs_throughput_mode' set to 'provisioned'."
  type        = number
  default     = 1024

  validation {
    condition     = var.efs_throughput_rate >= 1 && var.efs_throughput_rate <= 1024 && floor(var.efs_throughput_rate) == var.efs_throughput_rate
    error_message = "Valid values for `efs_throughput_rate` range from 1 to 1024 MiB/s."
  }
}

## Kubernetes
# Kubernetes version for the EKS cluster. Default is '1.32'.
variable "kubernetes_version" {
  description = "The EKS cluster Kubernetes version."
  type        = string
  default     = "1.32"
}

# Map of tags to apply to all resources. Used for cost allocation, project tracking, etc.
variable "tags" {
  description = "Map of common tags to be placed on the resources."
  type        = map(any)
  default     = { project_name = "viya" }
}

## Default node pool config
# Whether to create the default node pool for the cluster. If false, you must define your own node pools.
variable "create_default_nodepool" { # tflint-ignore: terraform_unused_declarations
  description = "Create Default Node Pool."
  type        = bool
  default     = true
}

# EC2 instance type for the default node pool (e.g., r6in.2xlarge).
variable "default_nodepool_vm_type" {
  description = "Type of the default node pool VMs."
  type        = string
  default     = "r6in.2xlarge"
}

# Disk type for default node pool VMs. Supported: 'gp3', 'gp2', 'io1'.
variable "default_nodepool_os_disk_type" {
  description = "Disk type for default node pool VMs."
  type        = string
  default     = "gp2"

  validation {
    condition     = contains(["gp3", "gp2", "io1"], lower(var.default_nodepool_os_disk_type))
    error_message = "ERROR: Supported values for `default_nodepool_os_disk_type` are gp3, gp2, or io1."
  }
}

# Disk size in GiB for default node pool VMs. Default is 200.
variable "default_nodepool_os_disk_size" {
  description = "Disk size for default node pool VMs."
  type        = number
  default     = 200
}

# Disk IOPS for default node pool VMs. Used for performance tuning.
variable "default_nodepool_os_disk_iops" {
  description = "Disk IOPS for default node pool VMs."
  type        = number
  default     = 0
}

# Initial number of nodes in the default node pool.
variable "default_nodepool_node_count" {
  description = "Initial number of nodes in the default node pool."
  type        = number
  default     = 1
}

# Maximum number of nodes in the default node pool.
variable "default_nodepool_max_nodes" {
  description = "Maximum number of nodes in the default node pool."
  type        = number
  default     = 5
}

# Minimum and initial number of nodes for the node pool.
variable "default_nodepool_min_nodes" {
  description = "Minimum and initial number of nodes for the node pool."
  type        = number
  default     = 1
}

# Taints for the default node pool VMs.
variable "default_nodepool_taints" {
  description = "Taints for the default node pool VMs."
  type        = list(any)
  default     = []
}

# Labels to add to the default node pool.
variable "default_nodepool_labels" {
  description = "Labels to add to the default node pool."
  type        = map(any)
  default = {
    "kubernetes.azure.com/mode" = "system"
  }
}

# Additional user data that will be appended to the default user data.
variable "default_nodepool_custom_data" {
  description = "Additional user data that will be appended to the default user data."
  type        = string
  default     = ""
}

# The state of the default node pool's metadata service.
variable "default_nodepool_metadata_http_endpoint" {
  description = "The state of the default node pool's metadata service."
  type        = string
  default     = "enabled"
}

# The state of the session tokens for the default node pool.
variable "default_nodepool_metadata_http_tokens" {
  description = "The state of the session tokens for the default node pool."
  type        = string
  default     = "required"
}

# The desired HTTP PUT response hop limit for instance metadata requests for the default node pool.
variable "default_nodepool_metadata_http_put_response_hop_limit" {
  description = "The desired HTTP PUT response hop limit for instance metadata requests for the default node pool."
  type        = number
  default     = 1
}

## Dynamic node pool config
# Node Pool Definitions.
variable "node_pools" {
  description = "Node Pool Definitions."
  type = map(object({
    vm_type                              = string
    cpu_type                             = string
    os_disk_type                         = string
    os_disk_size                         = number
    os_disk_iops                         = number
    subnet_number                        = number
    min_nodes                            = number
    max_nodes                            = number
    node_taints                          = list(string)
    node_labels                          = map(string)
    custom_data                          = string
    metadata_http_endpoint               = string
    metadata_http_tokens                 = string
    metadata_http_put_response_hop_limit = number
  }))

  default = {
    cas = {
      "vm_type"      = "r6idn.2xlarge"
      "cpu_type"     = "AL2023_x86_64_STANDARD"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "subnet_number" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
      "custom_data"                          = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    compute = {
      "vm_type"      = "m6idn.xlarge"
      "cpu_type"     = "AL2023_x86_64_STANDARD"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "subnet_number" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "custom_data"                          = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    stateless = {
      "vm_type"      = "m6in.xlarge"
      "cpu_type"     = "AL2023_x86_64_STANDARD"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "subnet_number" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
      "custom_data"                          = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    stateful = {
      "vm_type"      = "m6in.xlarge"
      "cpu_type"     = "AL2023_x86_64_STANDARD"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "subnet_number" = 0
      "min_nodes"    = 1
      "max_nodes"    = 3
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "custom_data"                          = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    }
  }
}

# Networking
# Pre-exising VPC id. Leave blank to have one created.
variable "vpc_id" {
  description = "Pre-exising VPC id. Leave blank to have one created."
  type        = string
  default     = null
}

# Map subnet usage roles to list of existing subnet ids.
variable "subnet_ids" {
  description = "Map subnet usage roles to list of existing subnet ids."
  type        = map(list(string))
  default     = {}
  # Example:
  # subnet_ids = {  # only needed if using pre-existing subnets
  #   "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  #   "private" : ["existing-private-subnet-id1"],
  #   "control_plane" : ["existing-control-plane-subnet-id1", "existing-control-plane-subnet-id2"],
  #   "database" : ["existing-database-subnet-id1", "existing-database-subnet-id2"] # only when 'create_postgres=true'
  # }
}

# VPC CIDR - NOTE: Subnets below must fall into this range.
variable "vpc_cidr" {
  description = "VPC CIDR - NOTE: Subnets below must fall into this range."
  type        = string
  default     = "192.168.0.0/16"
}

# Subnets to be created and their settings - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets).
variable "subnets" {
  description = "Subnets to be created and their settings - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets)."
  type        = map(list(string))
  default = {
    "private" : ["192.168.0.0/18"],
    "control_plane" : ["192.168.130.0/28", "192.168.130.16/28"], # AWS recommends at least 16 IP addresses per subnet
    "public" : ["192.168.129.0/25", "192.168.129.128/25"],
    "database" : ["192.168.128.0/25", "192.168.128.128/25"]
  }
}

# AZs you want the subnets to created in - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets).
variable "subnet_azs" {
  description = "AZs you want the subnets to created in - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets)."
  type        = map(list(string))
  default     = {}
  nullable    = false

  # We only support configuring the AZs for the public, private, control_plane, and database subnet
  validation {
    condition     = var.subnet_azs == {} || alltrue([for subnet in keys(var.subnet_azs) : contains(["public", "private", "control_plane", "database"], subnet)])
    error_message = "ERROR: public, private, control_plane, and database are the only keys allowed in the subnet_azs map"
  }
}
# Pre-existing Security Group id. Leave blank to have one created.
variable "security_group_id" {
  description = "Pre-existing Security Group id. Leave blank to have one created."
  type        = string
  default     = null
}

# Pre-existing Security Group id for the EKS Cluster. Leave blank to have one created.
variable "cluster_security_group_id" {
  description = "Pre-existing Security Group id for the EKS Cluster. Leave blank to have one created."
  type        = string
  default     = null
}

# Pre-existing Security Group id for the Cluster Node VM. Leave blank to have one created.
variable "workers_security_group_id" {
  description = "Pre-existing Security Group id for the Cluster Node VM. Leave blank to have one created."
  type        = string
  default     = null
}

# Pre-existing NAT Gateway id.
variable "nat_id" {
  description = "Pre-existing NAT Gateway id."
  type        = string
  default     = null
}

# ARN of the pre-existing IAM Role for the EKS cluster.
variable "cluster_iam_role_arn" {
  description = "ARN of the pre-existing IAM Role for the EKS cluster."
  type        = string
  default     = null
}

# ARN of the pre-existing IAM Role for the cluster node VMs.
variable "workers_iam_role_arn" {
  description = "ARN of the pre-existing IAM Role for the cluster node VMs."
  type        = string
  default     = null
}

# Create bastion Host VM.
variable "create_jump_vm" {
  description = "Create bastion Host VM."
  type        = bool
  default     = true
}

# Add public IP address to Jump VM.
variable "create_jump_public_ip" {
  description = "Add public IP address to Jump VM."
  type        = bool
  default     = true
}

# OS Admin User for Jump VM.
variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM."
  type        = string
  default     = "jumpuser"
}

# Jump VM type.
variable "jump_vm_type" {
  description = "Jump VM type."
  type        = string
  default     = "m6in.xlarge"
}

# OS path used in cloud-init for NFS integration.
variable "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration."
  type        = string
  default     = "/viya-share"
}

# Size in GB for each disk of the RAID0 cluster, when storage_type=standard.
variable "nfs_raid_disk_size" {
  description = "Size in GB for each disk of the RAID0 cluster, when storage_type=standard."
  type        = number
  default     = 128
}

# Disk type for the NFS server EBS volumes.
variable "nfs_raid_disk_type" {
  description = "Disk type for the NFS server EBS volumes."
  type        = string
  default     = "gp2"
}

# IOPS for the the NFS server EBS volumes.
variable "nfs_raid_disk_iops" {
  description = "IOPS for the the NFS server EBS volumes."
  type        = number
  default     = 0
}

# Add public IP address to the NFS server VM.
variable "create_nfs_public_ip" {
  description = "Add public IP address to the NFS server VM."
  type        = bool
  default     = false
}

# OS Admin User for NFS VM, when storage_type=standard.
variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard."
  type        = string
  default     = "nfsuser"
}

# NFS VM type.
variable "nfs_vm_type" {
  description = "NFS VM type."
  type        = string
  default     = "m6in.xlarge"
}

# Disk size for default node pool VMs in GB.
variable "os_disk_size" {
  description = "Disk size for default node pool VMs in GB."
  type        = number
  default     = 64
}

# Disk type for default node pool VMs.
variable "os_disk_type" {
  description = "Disk type for default node pool VMs."
  type        = string
  default     = "standard"
}

# Delete Disk on termination.
variable "os_disk_delete_on_termination" {
  description = "Delete Disk on termination."
  type        = bool
  default     = true
}

# Disk IOPS for default node pool VMs.
variable "os_disk_iops" {
  description = "Disk IOPS for default node pool VMs."
  type        = number
  default     = 0
}

## PostgresSQL

# Defaults
# Map of PostgresSQL server default objects.
variable "postgres_server_defaults" {
  description = "Map of PostgresSQL server default objects."
  type        = any
  default = {
    instance_type           = "db.m6idn.xlarge"
    storage_size            = 128
    storage_encrypted       = false
    backup_retention_days   = 7
    multi_az                = false
    deletion_protection     = false
    db_name                 = "SharedServices"
    administrator_login     = "pgadmin"
    administrator_password  = "my$up3rS3cretPassw0rd"
    server_version          = "15"
    server_port             = "5432"
    ssl_enforcement_enabled = true
    parameters              = []
    options                 = []
  }
}

# User inputs
# Map of PostgreSQL server objects provided by the user.
variable "postgres_servers" {
  description = "Map of PostgreSQL server objects provided by the user."
  type        = any
  default     = null

  # Checking for user provided "default" server
  validation {
    condition     = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? contains(keys(var.postgres_servers), "default") : false : true
    error_message = "ERROR: The provided map of PostgreSQL server objects does not contain the required 'default' key."
  }

  # Checking server name
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : alltrue([
        length(k) > 0,
        length(k) < 61,
        can(regex("^[a-zA-Z]+[a-zA-Z0-9-]*[a-zA-Z0-9]$", k)),
      ])
    ]) : false : true
    error_message = "ERROR: The database server name must start with a letter, cannot end with a hyphen, must be between 1-60 characters in length, and can only contain hyphends, letters, and numbers."
  }

  # Checking user provided login
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : contains(keys(v), "administrator_login") ? alltrue([
        v.administrator_login != "admin",
        length(v.administrator_login) > 0,
        length(v.administrator_login) < 17,
        can(regex("^[a-zA-Z][a-zA-Z0-9_]+$", v.administrator_login)),
      ]) : true
    ]) : false : true
    error_message = "ERROR: The admin login name can not be 'admin', must start with a letter, and must be between 1-16 characters in length, and can only contain underscores, letters, and numbers."
  }

  # Checking user provided password
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k, v in var.postgres_servers : contains(keys(v), "administrator_password") ? alltrue([
        length(v.administrator_password) > 7,
        can(regex("^[^/'\"@]+$", v.administrator_password)),
      ]) : true
    ]) : false : true
    error_message = "ERROR: The admin passsword must have more than 8 characters, and be composed of any printable characters except the following / ' \" @ characters."
  }
}

# Type of Storage. A value of 'standard' creates an NFS server VM; a value of 'ha' creates an AWS EFS mountpoint or AWS for NetApp ONTAP file system depending on the storage_type_backend
variable "storage_type" {
  description = "Type of Storage. A value of 'standard' creates an NFS server VM; a value of 'ha' creates an AWS EFS mountpoint or AWS for NetApp ONTAP file system depending on the storage_type_backend"
  type        = string
  default     = "standard"
  # NOTE: storage_type=none is for internal use only
  validation {
    condition     = contains(["standard", "ha", "none"], lower(var.storage_type))
    error_message = "ERROR: Supported values for `storage_type` are standard and ha."
  }
}

# The storage backend used for the chosen storage type. Defaults to 'nfs' for storage_type='standard'. Defaults to 'efs for storage_type='ha'. 'efs' and 'ontap' are valid choices for storage_type='ha'.
variable "storage_type_backend" {
  description = "The storage backend used for the chosen storage type. Defaults to 'nfs' for storage_type='standard'. Defaults to 'efs for storage_type='ha'. 'efs' and 'ontap' are valid choices for storage_type='ha'."
  type        = string
  default     = "nfs"
  # If storage_type is standard, this will be set to "nfs"

  validation {
    condition     = contains(["nfs", "efs", "ontap", "none"], lower(var.storage_type_backend))
    error_message = "ERROR: Supported values for `storage_type_backend` are nfs, efs, ontap and none."
  }
}

# Allows the user to create a provider- or service account-based kubeconfig file.
variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider- or service account-based kubeconfig file."
  type        = bool
  default     = true
}

# Use Public or Private IP address for the cluster API endpoint.
variable "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], lower(var.cluster_api_mode))
    error_message = "ERROR: Supported values for `cluster_api_mode` are - public, private."
  }
}

# Endpoints needed for private cluster.
variable "vpc_private_endpoints" { # tflint-ignore: terraform_unused_declarations
  description = "Endpoints needed for private cluster."
  type        = map(string)
  default = {
    "ec2"                  = "Interface",
    "ecr.api"              = "Interface",
    "ecr.dkr"              = "Interface",
    "s3"                   = "Interface",
    "logs"                 = "Interface",
    "sts"                  = "Interface",
    "elasticloadbalancing" = "Interface",
    "autoscaling"          = "Interface"
  }
}

# Enable the creation of vpc private endpoint resources
variable "vpc_private_endpoints_enabled" {
  description = "Enable the creation of vpc private endpoint resources"
  type        = bool
  default     = true
}

# Flag for predefined cluster node configurations. Supported values are default, minimal.
variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations. Supported values are default, minimal."
  type        = string
  default     = "default"

}

# Enable autoscaling for your AWS cluster.
variable "autoscaling_enabled" {
  description = "Enable autoscaling for your AWS cluster."
  type        = bool
  default     = true
}

# Enable encryption on EBS volumes.
variable "enable_ebs_encryption" {
  description = "Enable encryption on EBS volumes."
  type        = bool
  default     = false
}

# Enable encryption on EFS file systems.
variable "enable_efs_encryption" {
  description = "Enable encryption on EFS file systems."
  type        = bool
  default     = false
}

# The FSx filesystem availability zone deployment type. Supports MULTI_AZ_1 and SINGLE_AZ_1
variable "aws_fsx_ontap_deployment_type" {
  description = "The FSx filesystem availability zone deployment type. Supports MULTI_AZ_1 and SINGLE_AZ_1"
  type        = string
  default     = "SINGLE_AZ_1"

  validation {
    condition     = contains(["single_az_1", "multi_az_1"], lower(var.aws_fsx_ontap_deployment_type))
    error_message = "ERROR: Supported values for `fsx_ontap_deployment_type` are - SINGLE_AZ_1, MULTI_AZ_1."
  }
}

# The ONTAP administrative password for the fsxadmin user that you can use to administer your file system using the ONTAP CLI and REST API.
variable "aws_fsx_ontap_fsxadmin_password" {
  description = "The ONTAP administrative password for the fsxadmin user that you can use to administer your file system using the ONTAP CLI and REST API."
  type        = string
  default     = "v3RyS3cretPa$sw0rd"
}

# The ONTAP administrative password for the svmadmin user that you can use to administer your Storage Virtual Machine using the ONTAP CLI and REST API.
variable "aws_fsx_ontap_svmadmin_password" {
  description = "The ONTAP administrative password for the fsxadmin user that you can use to administer your Storage Virtual Machine using the ONTAP CLI and REST API."
  type        = string
  default     = "v3RyS3cretPa$sw0rd"
}

# The storage capacity (GiB) of the ONTAP file system. Valid values between 1024 and 196608.
variable "aws_fsx_ontap_file_system_storage_capacity" {
  description = "The storage capacity (GiB) of the ONTAP file system. Valid values between 1024 and 196608."
  type        = number
  default     = 1024

  validation {
    condition     = var.aws_fsx_ontap_file_system_storage_capacity >= 1024 && var.aws_fsx_ontap_file_system_storage_capacity <= 196608 && floor(var.aws_fsx_ontap_file_system_storage_capacity) == var.aws_fsx_ontap_file_system_storage_capacity
    error_message = "Valid values for `aws_fsx_ontap_file_system_storage_capacity` range from 1024 to 196608 GiB"
  }
}

# Sets the throughput capacity (in MBps) for the ONTAP file system that you're creating. Valid values are 128, 256, 512, 1024, 2048, and 4096.
variable "aws_fsx_ontap_file_system_throughput_capacity" {
  description = "Sets the throughput capacity (in MBps) for the ONTAP file system that you're creating. Valid values are 128, 256, 512, 1024, 2048, and 4096."
  type        = number
  default     = 256

  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 4096], var.aws_fsx_ontap_file_system_throughput_capacity)
    error_message = "Valid values for `aws_fsx_ontap_file_system_throughput_capacity` are 128, 256, 512, 1024, 2048 and 4096."
  }
}

# A flag to enable NIST features under development for this project
variable "enable_nist_features" {
  description = "A flag to enable NIST features under development for this project"
  type        = bool
  default     = false
}

# The authentication mode for the EKS cluster. Supported values are 'API_AND_CONFIG_MAP' and 'API'.
variable "authentication_mode" {
  description = "The authentication mode for the EKS cluster. Supported values are 'API_AND_CONFIG_MAP' and 'API'."
  type        = string
  default     = "API_AND_CONFIG_MAP"

  validation {
    condition     = contains(["API_AND_CONFIG_MAP", "API"], var.authentication_mode)
    error_message = "ERROR: Supported values for `authentication_mode` are API_AND_CONFIG_MAP and API."
  }
}

# List of IAM role ARNs to create admin EKS access_entries for.
variable "admin_access_entry_role_arns" {
  description = "List of IAM role ARNs to create admin EKS access_entries for."
  type        = list(string)
  default     = null
}
