# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
ssh_public_key                          = "~/.ssh/id_rsa.pub"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMENDED  VARIABLES  ***************
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
# **************  RECOMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

## Cluster config
kubernetes_version                      = "1.19"
default_nodepool_node_count             = 1
default_nodepool_vm_type                = "m5.large"
default_nodepool_custom_data            = ""

## General 
efs_performance_mode                    = "maxIO"
storage_type                            = "standard"

## Cluster Node Pools config - minimal
cluster_node_pool_mode   = "minimal"
node_pools = {
  cas = {
    "vm_type"            = "r5.xlarge"
    "os_disk_type"       = "gp2"
    "os_disk_size"       = 200
    "os_disk_iops"       = 0
    "min_nodes"          = 0
    "max_nodes"          = 5
    "node_taints"        = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = { 
      "workload.sas.com/class" = "cas" 
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  generic = {
    "vm_type"            = "m5.2xlarge"
    "os_disk_type"       = "gp2"
    "os_disk_size"       = 200
    "os_disk_iops"       = 0
    "min_nodes"          = 0
    "max_nodes"          = 5
    "node_taints"        = []
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  }
}

# Jump Server
create_jump_vm                        = true
jump_vm_admin                         = "jumpuser"
jump_vm_type                          = "t3.medium"

# NFS Server
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip                  = false
nfs_vm_admin                          = "nfsuser"
nfs_vm_type                           = "m5.xlarge"

# AWS Postgres config - By having this entry a database server is created. If you do not
#                       need an external database server remove the 'postgres_servers'
#                       block below.
# postgres_servers = {
#   default = {},
# }
