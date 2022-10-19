# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "viya"
location                                = "us-west-2" # e.g., "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = ["66.74.2.65/32", "54.185.4.107/32"]  # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/universal.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags                                    = {project_name = "viya"} # e.g., { "key1" = "value1", "key2" = "value2" }

# Postgres config - By having this entry a database server is created. If you do not
#                   need an external database server remove the 'postgres_servers'
#                   block below.
postgres_servers = {
  default = {},
}

## General
storage_type                            = "ha"
create_fsx_filestore                    = true
fsx_storage_capacity                    = 1200
fsx_deployment_type                     = "PERSISTENT_2"
fsx_per_unit_storage_throughput         = 125

## Cluster config
kubernetes_version                      = "1.21"
default_nodepool_node_count             = 1
default_nodepool_vm_type                = "m5.2xlarge"
default_nodepool_os_disk_type           = "gp3"
default_nodepool_ebs_optimized          = true
default_nodepool_os_disk_delete_on_termination = true
default_nodepool_os_disk_iops           = 125
default_nodepool_os_disk_throughput     = 250
default_nodepool_custom_data            = ""

## Cluster Node Pools config
node_pools = {
  cas = {
    "vm_type" = "m5.2xlarge"
    "cpu_type" = "AL2_x86_64"
    "ebs_optimized" = true
    "os_disk_delete_on_termination" = true
    "os_disk_iops" = 125
    "os_disk_throughput" = 250
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 1
    "node_taints" = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  compute = {
    "vm_type" = "m5.2xlarge"
    "cpu_type" = "AL2_x86_64"
    "ebs_optimized" = true
    "os_disk_delete_on_termination" = true
    "os_disk_iops" = 125
    "os_disk_throughput" = 250
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 1
    "node_taints" = ["workload.sas.com/class=compute:NoSchedule"]
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
    "vm_type" = "m5.2xlarge"
    "cpu_type" = "AL2_x86_64"
    "ebs_optimized" = true
    "os_disk_delete_on_termination" = true
    "os_disk_iops" = 125
    "os_disk_throughput" = 250
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 1
    "node_taints" = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  stateful = {
    "vm_type" = "m5.2xlarge"
    "cpu_type" = "AL2_x86_64"
    "ebs_optimized" = true
    "os_disk_delete_on_termination" = true
    "os_disk_iops" = 125
    "os_disk_throughput" = 250
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 1
    "node_taints" = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  }
}

# Jump Server
create_jump_vm                        = true
instance_profile_jump_vm              = true