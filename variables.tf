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
  description = "AWS Region to provision all resources in this script"
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Name of Profile in the credentials file"
  type        = string
  default     = ""
}

variable "aws_shared_credentials_file" {
  description = "Name of credentials file, if using non-default location"
  type        = string
  default     = ""
}

variable "aws_session_token" {
  description = "Session token for temporary credentials"
  type        = string
  default     = ""
}

variable "aws_access_key_id" {
  description = "Static credential key"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "Static credential secret"
  type        = string
  default     = ""
}

variable "iac_tooling" {
  description = "Value used to identify the tooling used to generate this provider's infrastructure"
  type        = string
  default     = "terraform"
}

## Public Access
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Public"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_private_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster - Private"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump VM or NFS VM"
  type        = list(string)
  default     = null
}

variable "postgres_public_access_cidrs" {
  description = "List of CIDRs to access PostgreSQL server"
  type        = list(string)
  default     = null
}

## Provider Specific
variable "ssh_public_key" {
  description = "SSH public key used to access VMs"
  default = "~/.ssh/id_rsa.pub"
}

variable efs_performance_mode {
  default = "generalPurpose"
}

## Kubernetes
variable "kubernetes_version" {
  description = "The EKS cluster Kubernetes version"
  default     = "1.23"
}

variable "tags" {
  description = "Map of common tags to be placed on the resources"
  type        = map
  default     = { project_name = "viya" }

  validation {
    condition = length(var.tags) > 0
    error_message = "ERROR: You must provide at last one tag."
  }
}

## Default node pool config
variable "create_default_nodepool" {
  description = "Create Default Node Pool"
  type        = bool
  default     = true
}

variable "default_nodepool_vm_type" {
  default = "m5.2xlarge"
}

variable "default_nodepool_os_disk_type" {
  type    = string
  default = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1"], lower(var.default_nodepool_os_disk_type))
    error_message = "ERROR: Supported values for `default_nodepool_os_disk_type` are gp3, gp2, io1."
  }
}

variable "default_nodepool_os_disk_size" {
  default = 200
}

variable "default_nodepool_os_disk_iops" {
  default = 0
}

variable "default_nodepool_node_count" {
  default = 1
}

variable "default_nodepool_max_nodes" {
  default = 5
}

variable "default_nodepool_min_nodes" {
  default = 1
}

variable "default_nodepool_taints" {
  type    = list
  default = []
}

variable "default_nodepool_labels" {
  type    = map
  default = {
    "kubernetes.azure.com/mode" = "system"
  }
}

variable "default_nodepool_custom_data" {
  default = ""
}

variable "default_nodepool_metadata_http_endpoint" {
  default = "enabled"
}

variable "default_nodepool_metadata_http_tokens" {
  default = "required"
}

variable "default_nodepool_metadata_http_put_response_hop_limit" {
  default = 1
}

## Dynamic node pool config
variable node_pools {
  description = "Node pool definitions"
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
      "os_disk_type" = "gp3"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
      "custom_data" = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    compute = {
      "vm_type"      = "m5.8xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp3"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "compute"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "custom_data" = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    stateless = {
      "vm_type"      = "m5.4xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp3"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
      "custom_data" = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    },
    stateful = {
      "vm_type"      = "m5.4xlarge"
      "cpu_type"     = "AL2_x86_64"
      "os_disk_type" = "gp3"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 3
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "custom_data" = ""
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
    }
  }
}

# Networking
variable "vpc_id" {
  type    = string
  default = null
  description = "Pre-exising VPC id. Leave blank to have one created"
}

variable "subnet_ids" {
  type = map(list(string))
  default     = {}
  description = "Map subnet usage roles to list of existing subnet ids"
  # Example:
  # subnet_ids = {  # only needed if using pre-existing subnets
  #   "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  #   "private" : ["existing-private-subnet-id1", "existing-private-subnet-id2"],
  #   "database" : ["existing-database-subnet-id1", "existing-database-subnet-id2"] # only when 'create_postgres=true'
  # }
}

variable "vpc_cidr" {
  description = "VPC CIDR - NOTE: Subnets below must fall into this range"
  default     = "192.168.0.0/16"
}

variable subnets {
  type = map
  description = "value"
  default = {
    "private" : ["192.168.0.0/18", "192.168.64.0/18"],
    "public" : ["192.168.129.0/25", "192.168.129.128/25"],
    "database" : ["192.168.128.0/25", "192.168.128.128/25"]
    }
}

variable "security_group_id" {
  type    = string
  default = null
  description = "Pre-existing Security Group id. Leave blank to have one created"

}

variable "cluster_security_group_id" {
  type    = string
  default = null
  description = "Pre-existing Security Group id for the EKS Cluster. Leave blank to have one created"
}

variable "workers_security_group_id" {
  type    = string
  default = null
  description = "Pre-existing Security Group id for the Cluster Node VM. Leave blank to have one created"
}

variable "nat_id" {
  type = string
  default = null
  description = "Pre-existing NAT Gateway id"
}

variable "cluster_iam_role_name" {
  type = string
  default = null
  description = "Pre-existing IAM Role for the EKS cluster"
}

variable "workers_iam_role_name" {
  type = string
  default = null
  description = "Pre-existing IAM Role for the Node VMs"
}


variable "create_jump_vm" {
  description = "Create bastion host VM"
  default = true
}

variable "create_jump_public_ip" {
  type    = bool
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}

variable "jump_vm_type" {
  description = "Jump VM type"
  default     = "m5.4xlarge"
}

variable "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration"
  default     = "/viya-share"
}

variable "nfs_raid_disk_size" {
  description = "Size in GB for each disk of the RAID0 cluster, when storage_type=standard"
  default     = 128
}

variable "nfs_raid_disk_type" {
  default = "gp3"
}

variable "nfs_raid_disk_iops" {
  default = 0
}

variable "create_nfs_public_ip" {
  type    = bool
  default = false
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard"
  default     = "nfsuser"
}

variable "nfs_vm_type" {
  description = "NFS VM type"
  default    = "m5.4xlarge"
}

variable "os_disk_size" {
  default = 64
}

variable "os_disk_type" {
  default = "standard"
}

variable "os_disk_delete_on_termination" {
  default = true
}

variable "os_disk_iops" {
  default = 0
}

## PostgresSQL

# Defaults
variable "postgres_server_defaults" {
  description = ""
  type        = any
  default = {
    instance_type                = "db.m5.xlarge"
    storage_size                 = 50
    storage_encrypted            = false
    backup_retention_days        = 7
    multi_az                     = false
    deletion_protection          = false
    administrator_login          = "pgadmin"
    administrator_password       = "my$up3rS3cretPassw0rd"
    server_version               = "13"
    server_port                  = "5432"
    ssl_enforcement_enabled      = true
    parameters                   = []
    options                      = []
  }
}

# User inputs
variable "postgres_servers" {
  description = "Map of PostgreSQL server objects"
  type        = any
  default     = null

  # Checking for user provided "default" server
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? contains(keys(var.postgres_servers), "default") : false : true
    error_message = "ERROR: The provided map of PostgreSQL server objects does not contain the required 'default' key."
  }

  # Checking server name
  validation {
    condition = var.postgres_servers != null ? length(var.postgres_servers) != 0 ? alltrue([
      for k,v in var.postgres_servers : alltrue([
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
      for k,v in var.postgres_servers : contains(keys(v),"administrator_login") ? alltrue([
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
      for k,v in var.postgres_servers : contains(keys(v),"administrator_password") ? alltrue([
        length(v.administrator_password) > 7,
        can(regex("^[^/'\"@]+$", v.administrator_password)),
      ]) : true
    ]) : false : true
    error_message = "ERROR: The admin passsword must have more than 8 characters, and be composed of any printable characters except the following / ' \" @ characters."
  }
}

variable "storage_type" {
  type    = string
  default = "standard"
  # NOTE: storage_type=none is for internal use only
  validation {
    condition     = contains(["standard", "ha", "none"], lower(var.storage_type))
    error_message = "ERROR: Supported values for `storage_type` are standard, ha."
  }
}

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider- or service account-based kubeconfig file"
  type        = bool
  default     = true
}

variable "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], lower(var.cluster_api_mode))
    error_message = "ERROR: Supported values for `cluster_api_mode` are - public, private."
  }
}

variable "vpc_private_endpoints" {
   description = "Endpoints needed for private cluster"
   type        = list(string)
   default     = [ "ec2", "ecr.api", "ecr.dkr", "s3", "logs", "sts", "elasticloadbalancing", "autoscaling" ]
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
