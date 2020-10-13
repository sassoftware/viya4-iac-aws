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

variable "iam_profile" {
  description = "Name of Profile in the credentials file"
  type        = string
  default     = ""
}

variable "iam_shared_credentials_file" {
  description = "Name of credentials file, if using non-default location"
  type        = string
  default     = ""
}

variable "iam_session_token" {
  description = "Session token for temporary credentials"
  type        = string
  default     = ""
}

variable "iam_access_key" {
  description = "Static credential key"
  type        = string
  default     = ""
}

variable "iam_secret_key" {
  description = "Static credential secret"
  type        = string
  default     = ""
}


## Provider Specific 
variable "ssh_public_key" {
  default = ""
}

## Kubernetes
variable "kubernetes_version" {
  description = "The EKS cluster K8s version"
  default     = "1.17"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDRs allowed to access the cluster"
  type        = list
  default     = []
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
  default = "gp2"
}

variable "default_nodepool_os_disk_size" {
  default = 200
}

variable "default_nodepool_initial_node_count" {
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
  type    = list
  default = []
}

# CAS Nodepool config
variable "create_cas_nodepool" {
  description = "Create CAS Node Pool"
  type        = bool
  default     = true
}

variable "cas_nodepool_vm_type" {
  default = "m5.8xlarge"
}

variable "cas_nodepool_os_disk_type" {
  default = "gp2"
}

variable "cas_nodepool_os_disk_size" {
  default = 200
}

variable "cas_nodepool_initial_node_count" {
  default = 1
}

variable "cas_nodepool_max_nodes" {
  default = 5
}

variable "cas_nodepool_min_nodes" {
  default = 1
}

variable "cas_nodepool_taints" {
  type    = list
  default = ["workload.sas.com/class=cas:NoSchedule"]
}

variable "cas_nodepool_labels" {
  type    = list
  default = ["workload.sas.com/class=cas"]
}

# Compute Nodepool config
variable "create_compute_nodepool" {
  description = "Create Compute Node Pool"
  type        = bool
  default     = true
}

variable "compute_nodepool_vm_type" {
  default = "m5.8xlarge"
}

variable "compute_nodepool_os_disk_type" {
  default = "gp2"
}

variable "compute_nodepool_os_disk_size" {
  default = 200
}

variable "compute_nodepool_initial_node_count" {
  default = 1
}

variable "compute_nodepool_max_nodes" {
  default = 5
}

variable "compute_nodepool_min_nodes" {
  default = 1
}

variable "compute_nodepool_taints" {
  type    = list
  default = ["workload.sas.com/class=compute:NoSchedule"]
}

variable "compute_nodepool_labels" {
  type    = list
  default = ["workload.sas.com/class=compute"]
}

# stateless Nodepool config
variable "create_stateless_nodepool" {
  description = "Create Stateless Node Pool"
  type        = bool
  default     = true
}

variable "stateless_nodepool_vm_type" {
  default = "m5.4xlarge"
}

variable "stateless_nodepool_os_disk_type" {
  default = "gp2"
}

variable "stateless_nodepool_os_disk_size" {
  default = 200
}

variable "stateless_nodepool_initial_node_count" {
  default = 1
}

variable "stateless_nodepool_max_nodes" {
  default = 5
}

variable "stateless_nodepool_min_nodes" {
  default = 1
}

variable "stateless_nodepool_taints" {
  type    = list
  default = ["workload.sas.com/class=stateless:NoSchedule"]
}

variable "stateless_nodepool_labels" {
  type    = list
  default = ["workload.sas.com/class=stateless"]
}

# stateful Nodepool config
variable "create_stateful_nodepool" {
  description = "Create the Stateful Node Pool"
  type        = bool
  default     = true
}

variable "stateful_nodepool_vm_type" {
  default = "m5.2xlarge"
}

variable "stateful_nodepool_os_disk_type" {
  default = "gp2"
}

variable "stateful_nodepool_os_disk_size" {
  default = 200
}

variable "stateful_nodepool_initial_node_count" {
  default = 1
}

variable "stateful_nodepool_max_nodes" {
  default = 3
}

variable "stateful_nodepool_min_nodes" {
  default = 1
}

variable "stateful_nodepool_taints" {
  type    = list
  default = ["workload.sas.com/class=stateful:NoSchedule"]
}

variable "stateful_nodepool_labels" {
  type    = list
  default = ["workload.sas.com/class=stateful"]
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

# Network Security Rules
variable "sg_ingress_rules" {
  type = list(object({
    name        = string
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      name        = "INGRESS-HTTP"
      description = "Allow HTTP from source"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    },
    {
      name        = "INGRESS-HTTPS"
      description = "Allow HTTPS from source"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    },
    {
      name        = "INGRESS-SSH"
      description = "Allow SSH from source"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    },
    {
      name        = "INGRESS-kubectl"
      description = "Allow kubectl from source"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    },
    {
      name        = "INGRESS-CAS"
      description = "Allow CAS from source"
      from_port   = 5570
      to_port     = 5570
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    },
    {
      name        = "INGRESS-POSTGRES"
      description = "Allow Postgres from source"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      # TODO: remove before publishing externally
      cidr_blocks = []
    }
  ]
}

variable "sg_egress_rules" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))

  default = [
    {
      description = "Allow all outbound traffic."
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable create_jump_vm {
  default = true
}

variable "jump_vm_admin" {
  description = "OS Admin User for Jump VM"
  default     = "jumpuser"
}

variable "data_disk_count" {
  default = 0
}

variable "data_disk_size" {
  default = 128
}

variable "data_disk_type" {
  default = "gp2"
}

variable "data_disk_delete_on_termination" {
  default = true
}

variable "data_disk_iops" {
  default = 0
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

