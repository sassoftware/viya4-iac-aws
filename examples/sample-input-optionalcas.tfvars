# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>"
location = "<aws-location-value>" # e.g., "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags = {} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

## Cluster config
kubernetes_version           = "1.32"
default_nodepool_node_count  = 2
default_nodepool_vm_type     = "r6in.2xlarge"
default_nodepool_custom_data = ""

## General
efs_performance_mode = "maxIO"
storage_type         = "standard"

# ****************  OPTIONAL CAS CONFIGURATION  ****************
# This configuration is optimized for SAS Viya Programming-only deployments.
# 
# Keep the cas block commented out to avoid CAS node pool creation:
#    - No CAS node pool or EC2 instances created
#    - Zero cost for CAS infrastructure
# ******************************************************************

## Cluster Node Pools config
node_pools = {
#  cas = {
#    "vm_type"      = "r6idn.2xlarge"
#    "cpu_type"     = "AL2023_x86_64_STANDARD"
#    "os_disk_type" = "gp2"
#    "os_disk_size" = 200
#    "os_disk_iops" = 0
#    "min_nodes"    = 0
#    "max_nodes"    = 5
#    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
#    "node_labels" = {
#      "workload.sas.com/class" = "cas"
#    }
#    "custom_data"                          = ""
#    "metadata_http_endpoint"               = "enabled"
#    "metadata_http_tokens"                 = "required"
#    "metadata_http_put_response_hop_limit" = 1
#  },
  compute = {
    "vm_type"      = "m6idn.xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD"
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
    "vm_type"      = "m6in.xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD"
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
    "vm_type"      = "m6in.xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD"
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


# Jump Server
create_jump_vm = true
jump_vm_admin  = "jumpuser"
jump_vm_type   = "t3.medium"

# NFS Server
# required ONLY when storage_type is "standard" to create NFS Server VM
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_type          = "m6in.xlarge"