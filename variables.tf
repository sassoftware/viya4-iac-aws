# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## Global
variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with a lowercase letter and contain only alphanumeric characters and hyphens or dashes (-), but cannot start or end with '-'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, hyphens, or dashes (-), but cannot start or end with '-'."
  }
}

## Provider
variable "location" {
  description = "AWS Region to provision all resources in this script."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Name of Profile in the credentials file."
  type        = string
  default     = ""
}

variable "aws_shared_credentials_file" {
  description = "Name of credentials file, if using non-default location."
  type        = string
  default     = ""
}

variable "aws_shared_credentials_files" {
  description = "List of paths to shared credentials files, if using non-default location."
  type        = list(string)
  default     = null
}

variable "aws_session_token" {
  description = "Session token for temporary credentials."
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "Static credential key."
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "Static credential secret."
  type        = string
  default     = ""
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this provider's infrastructure."
  type        = string
  default     = "terraform"
}

## Public Access
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources."
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Public."
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Private."
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump VM or NFS VM."
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server."
  type        = list(string)
  default     = null
}

## Provider Specific
variable "ssh_public_key" {
  description = "SSH public key used to access VMs."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "efs_performance_mode" {
  description = "EFS performance mode. Supported values are `generalPurpose` or `maxIO`."
  type        = string
  default     = "generalPurpose"
}

variable "efs_throughput_mode" {
  description = "EFS throughput mode. Supported values are 'bursting' and 'provisioned'. When using 'provisioned', 'efs_throughput_rate' is required."
  type        = string
  default     = "bursting"

  validation {
    condition     = contains(["bursting", "provisioned"], lower(var.efs_throughput_mode))
    error_message = "ERROR: Supported values for `efs_throughput_mode` are - bursting, provisioned."
  }
}

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
variable "kubernetes_version" {
  description = "The EKS cluster Kubernetes version."
  type        = string
  default     = "1.26"
}

variable "tags" {
  description = "Map of common tags to be placed on the resources."
  type        = map(any)
  default     = { project_name = "viya" }
}

## Default node pool config
variable "create_default_nodepool" { # tflint-ignore: terraform_unused_declarations
  description = "Create Default Node Pool."
  type        = bool
  default     = true
}

variable "default_nodepool_vm_type" {
  description = "Type of the default node pool VMs."
  type        = string
  default     = "m5.2xlarge"
}

variable "default_nodepool_os_disk_type" {
  description = "Disk type for default node pool VMs."
  type        = string
  default     = "gp2"

  validation {
    condition     = contains(["gp2", "io1"], lower(var.default_nodepool_os_disk_type))
    error_message = "ERROR: Supported values for `default_nodepool_os_disk_type` are gp2, io1."
  }
}

variable "default_nodepool_os_disk_size" {
  description = "Disk size for default node pool VMs."
  type        = number
  default     = 200
}

variable "default_nodepool_os_disk_iops" {
  description = "Disk IOPS for default node pool VMs."
  type        = number
  default     = 0
}

variable "default_nodepool_node_count" {
  description = "Initial number of nodes in the default node pool."
  type        = number
  default     = 1
}

variable "default_nodepool_max_nodes" {
  description = "Maximum number of nodes in the default node pool."
  type        = number
  default     = 5
}

variable "default_nodepool_min_nodes" {
  description = "Minimum and initial number of nodes for the node pool."
  type        = number
  default     = 1
}

variable "default_nodepool_taints" {
  description = "Taints for the default node pool VMs."
  type        = list(any)
  default     = []
}

variable "default_nodepool_labels" {
  description = "Labels to add to the default node pool."
  type        = map(any)
  default = {
    "kubernetes.azure.com/mode" = "system"
  }
}

variable "default_nodepool_custom_data" {
  description = "Additional user data that will be appended to the default user data."
  type        = string
  default     = ""
}

variable "default_nodepool_metadata_http_endpoint" {
  description = "The state of the default node pool's metadata service."
  type        = string
  default     = "enabled"
}

variable "default_nodepool_metadata_http_tokens" {
  description = "The state of the session tokens for the default node pool."
  type        = string
  default     = "required"
}

variable "default_nodepool_metadata_http_put_response_hop_limit" {
  description = "The desired HTTP PUT response hop limit for instance metadata requests for the default node pool."
  type        = number
  default     = 1
}

## Dynamic node pool config
variable "node_pools" {
  description = "Node Pool Definitions."
  type = map(object({
    vm_type                              = string
    cpu_type                             = string
    os_disk_type                         = string
    os_disk_size                         = number
    os_disk_iops                         = number
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
      "vm_type"      = "m5.2xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
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
      "vm_type"      = "m5.8xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
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
      "vm_type"      = "m5.4xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
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
      "vm_type"      = "m5.4xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
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
variable "vpc_id" {
  description = "Pre-exising VPC id. Leave blank to have one created."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Map subnet usage roles to list of existing subnet ids."
  type        = map(list(string))
  default     = {}
  # Example:
  # subnet_ids = {  # only needed if using pre-existing subnets
  #   "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  #   "private" : ["existing-private-subnet-id1", "existing-private-subnet-id2"],
  #   "database" : ["existing-database-subnet-id1", "existing-database-subnet-id2"] # only when 'create_postgres=true'
  # }
}

variable "vpc_cidr" {
  description = "VPC CIDR - NOTE: Subnets below must fall into this range."
  type        = string
  default     = "192.168.0.0/16"
}

variable "subnets" {
  description = "Subnets to be created and their settings - This variable is ignored when `subnet_ids` is set (AKA bring your own subnets)."
  type        = map(list(string))
  default = {
    "private" : ["192.168.0.0/18", "192.168.64.0/18"],
    "public" : ["192.168.129.0/25", "192.168.129.128/25"],
    "database" : ["192.168.128.0/25", "192.168.128.128/25"]
  }
}

variable "security_group_id" {
  description = "Pre-existing Security Group id. Leave blank to have one created."
  type        = string
  default     = null
}

variable "cluster_security_group_id" {
  description = "Pre-existing Security Group id for the EKS Cluster. Leave blank to have one created."
  type        = string
  default     = null
}

variable "workers_security_group_id" {
  description = "Pre-existing Security Group id for the Cluster Node VM. Leave blank to have one created."
  type        = string
  default     = null
}

variable "nat_id" {
  description = "Pre-existing NAT Gateway id."
  type        = string
  default     = null
}

variable "cluster_iam_role_arn" {
  description = "ARN of the pre-existing IAM Role for the EKS cluster."
  type        = string
  default     = null
}

variable "workers_iam_role_arn" {
  description = "ARN of the pre-existing IAM Role for the cluster node VMs."
  type        = string
  default     = null
}

variable "create_jump_vm" {
  description = "Create bastion Host VM."
  type        = bool
  default     = true
}

variable "create_jump_public_ip" {
  description = "Add public IP address to Jump VM."
  type        = bool
  default     = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM."
  type        = string
  default     = "jumpuser"
}

variable "jump_vm_type" {
  description = "Jump VM type."
  type        = string
  default     = "m5.4xlarge"
}

variable "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration."
  type        = string
  default     = "/viya-share"
}

variable "nfs_raid_disk_size" {
  description = "Size in GB for each disk of the RAID0 cluster, when storage_type=standard."
  type        = number
  default     = 128
}

variable "nfs_raid_disk_type" {
  description = "Disk type for the NFS server EBS volumes."
  type        = string
  default     = "gp2"
}

variable "nfs_raid_disk_iops" {
  description = "IOPS for the the NFS server EBS volumes."
  type        = number
  default     = 0
}

variable "create_nfs_public_ip" {
  description = "Add public IP address to the NFS server VM."
  type        = bool
  default     = false
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard."
  type        = string
  default     = "nfsuser"
}

variable "nfs_vm_type" {
  description = "NFS VM type."
  type        = string
  default     = "m5.4xlarge"
}

variable "os_disk_size" {
  description = "Disk size for default node pool VMs in GB."
  type        = number
  default     = 64
}

variable "os_disk_type" {
  description = "Disk type for default node pool VMs."
  type        = string
  default     = "standard"
}

variable "os_disk_delete_on_termination" {
  description = "Delete Disk on termination."
  type        = bool
  default     = true
}

variable "os_disk_iops" {
  description = "Disk IOPS for default node pool VMs."
  type        = number
  default     = 0
}

## PostgresSQL

# Defaults
variable "postgres_server_defaults" {
  description = "Map of PostgresSQL server default objects."
  type        = any
  default = {
    instance_type           = "db.m5.xlarge"
    storage_size            = 50
    storage_encrypted       = false
    backup_retention_days   = 7
    multi_az                = false
    deletion_protection     = false
    administrator_login     = "pgadmin"
    administrator_password  = "my$up3rS3cretPassw0rd"
    server_version          = "13"
    server_port             = "5432"
    ssl_enforcement_enabled = true
    parameters              = []
    options                 = []
  }
}

# User inputs
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

variable "storage_type" {
  description = "Type of Storage. A value of 'standard' creates an NFS server VM; a value of 'ha' creates an AWS EFS mountpoint."
  type        = string
  default     = "standard"
  # NOTE: storage_type=none is for internal use only
  validation {
    condition     = contains(["standard", "ha", "none"], lower(var.storage_type))
    error_message = "ERROR: Supported values for `storage_type` are standard and ha."
  }
}

# TODO: It may become useful to pass this to the DAC side as an output in the future
variable "storage_type_backend" {
  description = "The storage backend used for the chosen storage type. Defaults to 'nfs' for storage_type='standard'. Defaults to 'efs for storage_type-'ha'. 'efs' and 'ontap' are valid choices for storage_type='ha'."
  type        = string
  default     = "nfs"
  # If storage_type is standard, this will be set to "nfs"

  validation {
    condition     = contains(["nfs", "efs", "ontap", "none"], lower(var.storage_type_backend))
    error_message = "ERROR: Supported values for `storage_type_backend` are nfs, efs, ontap and none."
  }
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider- or service account-based kubeconfig file."
  type        = bool
  default     = true
}

variable "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], lower(var.cluster_api_mode))
    error_message = "ERROR: Supported values for `cluster_api_mode` are - public, private."
  }
}

variable "vpc_private_endpoints" { # tflint-ignore: terraform_unused_declarations
  description = "Endpoints needed for private cluster."
  type        = list(string)
  default     = ["ec2", "ecr.api", "ecr.dkr", "s3", "logs", "sts", "elasticloadbalancing", "autoscaling"]
}

variable "cluster_node_pool_mode" {
  description = "Flag for predefined cluster node configurations. Supported values are default, minimal."
  type        = string
  default     = "default"

}

variable "autoscaling_enabled" {
  description = "Enable autoscaling for your AWS cluster."
  type        = bool
  default     = true
}

variable "enable_ebs_encryption" {
  description = "Enable encryption on EBS volumes."
  type        = bool
  default     = false
}

variable "enable_efs_encryption" {
  description = "Enable encryption on EFS file systems."
  type        = bool
  default     = false
}

variable "aws_fsx_ontap_deployment_type" {
  description = "The FSx filesystem availability zone deployment type. Supports MULTI_AZ_1 and SINGLE_AZ_1"
  type        = string
  default     = "SINGLE_AZ_1"

  validation {
    condition     = contains(["single_az_1", "multi_az_1"], lower(var.aws_fsx_ontap_deployment_type))
    error_message = "ERROR: Supported values for `fsx_ontap_deployment_type` are - SINGLE_AZ_1, MULTI_AZ_1."
  }
}

variable "aws_fsx_ontap_fsxadmin_password" {
  description = "The ONTAP administrative password for the fsxadmin user that you can use to administer your file system using the ONTAP CLI and REST API."
  type        = string
  default     = "v3RyS3cretPa$sw0rd"
}

variable "aws_fsx_ontap_file_system_storage_capacity" {
  description = "The storage capacity (GiB) of the ONTAP file system. Valid values between 1024 and 196608."
  type        = number
  default     = 1024

  validation {
    condition     = var.aws_fsx_ontap_file_system_storage_capacity >= 1024 && var.aws_fsx_ontap_file_system_storage_capacity <= 196608 && floor(var.aws_fsx_ontap_file_system_storage_capacity) == var.aws_fsx_ontap_file_system_storage_capacity
    error_message = "Valid values for `aws_fsx_ontap_file_system_storage_capacity` range from 1024 to 196608 GiB"
  }
}

variable "aws_fsx_ontap_file_system_throughput_capacity" {
  description = "Sets the throughput capacity (in MBps) for the ONTAP file system that you're creating. Valid values are 128, 256, 512, 1024, 2048, and 4096."
  type        = number
  default     = 512

  validation {
    condition     = contains([128, 256, 512, 1024, 2048, 4096], var.aws_fsx_ontap_file_system_throughput_capacity)
    error_message = "Valid values for `aws_fsx_ontap_file_system_throughput_capacity` are 128, 256, 512, 1024, 2048 and 4096."
  }
}
