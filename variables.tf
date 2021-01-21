## Global
variable "prefix" {
  description = "A prefix used in the name for all the cloud resources created by this script. The prefix string must start with lowercase letter and contain only alphanumeric characters."
  type        = string

  # validation {
  #   condition = can(regex("^[a-z][a-zA-Z0-9]*$", var.prefix))
  #   # condition     = length(var.prefix) < 7 && can(regex("^[a-z][a-zA-Z0-9]*$", var.prefix))
  #   error_message = "ERROR: Input Value of 'prefix' must start with lowercase letter and can contain only alphanumeric characters [a-zA-Z0-9]."
  # }
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

## Public Access
variable "default_public_access_cidrs" {
  description = "List of CIDRs to access created resources"
  type        = list(string)
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs to access Kubernetes cluster"
  type        = list(string)
  default     = null
}

variable "vm_public_access_cidrs" {
  description = "List of CIDRs to access jump or nfs VM"
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
  description = "ssh public key used to access VMs"
  default = "~/.ssh/id_rsa.pub"
}

variable efs_performance_mode {
  default = "generalPurpose"
}

## Kubernetes
variable "kubernetes_version" {
  description = "The EKS cluster K8s version"
  default     = "1.18"
}

variable "tags" {
  description = "Map of common tags to be placed on the Resources"
  type        = map
  default     = { project_name = "viya" }
}

## Default Nodepool config
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
  default = "gp2"

  validation {
    condition     = contains(["gp2", "io1"], lower(var.default_nodepool_os_disk_type))
    error_message = "ERROR: Support value for `default_nodepool_os_disk_type` are - gp2, io1."
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
  default = {}
}

variable "default_nodepool_custom_data" {
  default = ""
}

## Dynamnic Nodepool config
variable node_pools {
  description = "Node pool definitions"
  type = map(object({
    vm_type      = string
    os_disk_type = string
    os_disk_size = number
    os_disk_iops = number
    min_nodes    = string
    max_nodes    = string
    node_taints  = list(string)
    node_labels  = map(string)
    custom_data  = string
  }))

  default = {
    cas = {
      "vm_type"      = "m5.2xlarge"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "cas"
      }
      "custom_data" = ""
    },
    compute = {
      "vm_type"      = "m5.8xlarge"
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
      "custom_data" = ""
    },
    connect = {
      "vm_type"      = "m5.8xlarge"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=connect:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class"        = "connect"
        "launcher.sas.com/prepullImage" = "sas-programming-environment"
      }
      "custom_data" = ""
    },
    stateless = {
      "vm_type"      = "m5.4xlarge"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 5
      "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateless"
      }
      "custom_data" = ""
    },
    stateful = {
      "vm_type"      = "m5.4xlarge"
      "os_disk_type" = "gp2"
      "os_disk_size" = 200
      "os_disk_iops" = 0
      "min_nodes"    = 1
      "max_nodes"    = 3
      "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
      "node_labels" = {
        "workload.sas.com/class" = "stateful"
      }
      "custom_data" = ""
    }
  }
}

variable "vpc_cidr" {
  description = "VPC CIDR - NOTE: Subnets below must fall into this range"
  default     = "192.168.0.0/16"
}

# Subnet - gw
variable "public_subnets" {
  description = "List of public subnets for use in the AWS EKS cluster"
  default     = ["192.168.129.0/25", "192.168.129.128/25"]
}

# Subnets - eks/misc
variable "private_subnets" {
  description = "List of private subnets for use in the AWS EKS cluster"
  default     = ["192.168.0.0/18", "192.168.64.0/18"]
}

# Subnets - database
variable "database_subnets" {
  description = "List of private subnets for use in the AWS EKS cluster"
  default     = ["192.168.128.0/25", "192.168.128.128/25"]
}

variable "create_jump_vm" {
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}

variable "nfs_raid_disk_size" {
  description = "Size in Gb for each disk of the RAID0 cluster, when storage_type=standard"
  default     = 128
}

variable "nfs_raid_disk_type" {
  default = "gp2"
}

variable "nfs_raid_disk_iops" {
  default = 0
}

variable "create_nfs_public_ip" {
  default = false
}

variable "nfs_vm_admin" {
  description = "OS Admin User for NFS VM, when storage_type=standard"
  default     = "nfsuser"
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
variable "create_postgres" {
  description = "Create an AWS Postgres DB (RDS)"
  type        = bool
  default     = false
}

variable "postgres_server_name" {
  description = "Specifies the name of the PostgreSQL Server. Changing this forces a new resource to be created."
  default     = ""
}

variable "postgres_server_version" {
  default = "11"
}

variable "postgres_server_port" {
  default = "5432"
}

variable "postgres_instance_type" {
  default = "db.m5.xlarge"
}

variable "postgres_storage_size" {
  default = "50"
}

variable "postgres_backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  default     = 7
}

variable "postgres_storage_encrypted" {
  type    = bool
  default = false
}

variable "postgres_administrator_login" {
  default = "pgadmin"
}

variable "postgres_administrator_password" {
  default = ""
}

variable "postgres_db_name" {
  default = "SharedServices"
}

variable "postgres_multi_az" {
  default = false
}

variable "postgres_deletion_protection" {
  default = false
}

variable "postgres_parameters" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "postgres_options" {
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}
variable "storage_type" {
  type    = string
  default = "standard"

  validation {
    condition     = contains(["standard", "ha"], lower(var.storage_type))
    error_message = "ERROR: Supported value for `storage_type` are - standard, ha."
  }
}

variable user_dir {
  default = "."
  description = "Directory where output file are written."
}
