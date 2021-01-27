# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
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
kubernetes_version                      = "1.18"
default_nodepool_node_count             = 2
default_nodepool_vm_type                = "m5.2xlarge"
default_nodepool_custom_data            = ""

## General 
efs_performance_mode                    = "maxIO"
storage_type                            = "standard"

## Cluster Node Pools config
node_pools = {
  cas = {
    "vm_type" = "m5.2xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
      "workload.sas.com/node"  = ""
    }
    "custom_data" = ""
  },
  compute = {
    "vm_type" = "m5.8xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "workload.sas.com/node"         = ""
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
  },
  connect = {
    "vm_type" = "m5.8xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "workload.sas.com/node"         = ""
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
  },
  stateless = {
    "vm_type" = "m5.4xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
      "workload.sas.com/node"  = ""
    }
    "custom_data" = ""
  },
  stateful = {
    "vm_type" = "m5.4xlarge"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes" = 1
    "max_nodes" = 3
    "node_taints" = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
      "workload.sas.com/node"  = ""
    }
    "custom_data" = ""
  }
}

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
create_postgres                       = true # set this to "false" when using internal Crunchy Postgres and AWS Postgres is NOT needed
postgres_administrator_password       = "mySup3rS3cretPassw0rd"
