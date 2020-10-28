# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }
# ****************  REQUIRED VARIABLES  ****************

# When a ssh key value is provided it will be used for all VMs or else a ssh key will be auto generated and available in outputs
ssh_public_key                          = "~/.ssh/id_rsa.pub"

## Cluster config
kubernetes_version                      = "1.18"
default_nodepool_node_count             = 2
default_nodepool_vm_type                = "m5.2xlarge"

## Cluster Node Pools config
node_pools = {
  cas = {
    "vm_type" = "m5.2xlarge"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
  },
  compute = {
    "vm_type" = "m5.8xlarge"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  connect = {
    "vm_type" = "m5.8xlarge"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=connect:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "connect"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
  },
  stateless = {
    "vm_type" = "m5.4xlarge"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 5
    "node_taints" = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
  },
  stateful = {
    "vm_type" = "m5.4xlarge"
    "os_disk_size" = 200
    "min_nodes" = 1
    "max_nodes" = 3
    "node_taints" = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
  }
}

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
create_postgres                       = true # set this to "false" when using internal Crunchy Postgres and AWS Postgres is NOT needed
postgres_administrator_password       = "mySup3rS3cretPassw0rd"

# Cloud Container Registry - NOT IMPLEMENTED
# create_container_registry             = false
