## Global
variable "prefix" {
  description = "A prefix used in the name for all cloud resources created by this script. The prefix string must start with lowercase letter and contain only alphanumeric characters and hyphen or dash(-), but can not start or end with '-'."
  type        = string

  validation {
    condition     = can(regex("^[a-z][-0-9a-z]*[0-9a-z]$", var.prefix))
    error_message = "ERROR: Value of 'prefix'\n * must start with lowercase letter\n * can only contain lowercase letters, numbers, and hyphen or dash(-), but can't start or end with '-'."
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
  description = "Value used to identify the tooling used to generate this providers infrastructure."
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
  default     = "1.19"
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

## Dynamnic Nodepool config
variable node_pools {
  description = "Node pool definitions"
  type = map(object({
    vm_type                              = string
    os_disk_type                         = string
    os_disk_size                         = number
    os_disk_iops                         = number
    min_nodes                            = string
    max_nodes                            = string
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
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
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
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
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
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
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
      "metadata_http_endpoint"               = "enabled"
      "metadata_http_tokens"                 = "required"
      "metadata_http_put_response_hop_limit" = 1
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

variable "nat_id" {
  type = string
  default = null
  description = "Pre-existing NAT Gateway id"
}

variable "create_jump_vm" {
  description = "Create bastion host VM"
  default = true
}

variable "create_jump_public_ip" {
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
  default = null
  #TODO: add validation
}

variable "postgres_db_name" {
  default = ""
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

variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = true
}

variable "private_cluster" {
  description = "Use Private IP address for cluster API endpoint"
  type        = bool
  default     = false
}

variable "vpc_private_endpoints" {
   description = "Endpoints needed for private cluster"
   type        = list(string)
   default     = [ "ec2", "ecr.api", "ecr.dkr", "s3", "logs", "sts", "elasticloadbalancing", "autoscaling" ]
}
