# !NOTE! - These are only a subset of CONFIG-VARS.md provided for sample.
# Customize this file to add any variables from 'CONFIG-VARS.md' that you want 
# to change their default values.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
ssh_public_key                          = "~/.ssh/id_rsa.pub"
# ****************  REQUIRED VARIABLES  ****************

# Bring your own existing resources
vpc_id  = "<existing-vpc-id>" # only needed if using pre-existing VPC
subnet_ids = {  # only needed if using pre-existing subnets
  "public" : ["existing-public-subnet-id1", "existing-public-subnet-id2"],
  "private" : ["existing-private-subnet-id1", "existing-private-subnet-id2"],
  "database" : ["existing-database-subnet-id1", "existing-database-subnet-id2"] # only when 'create_postgres=true' 
}
nat_id = "<existing-NAT-gateway-id>"
security_group_id = "<existing-security-group-id>" # only needed if using pre-existing Security Group

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMENDED  VARIABLES  ***************
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
# **************  RECOMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

## Cluster config
kubernetes_version                      = "1.19"
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
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
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
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
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
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
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
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
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
    }
    "custom_data" = ""
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  }
}

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
create_postgres                       = true # set this to "false" when using internal Crunchy Postgres and AWS Postgres is NOT needed
postgres_ssl_enforcement_enabled      = false
postgres_administrator_password       = "mySup3rS3cretPassw0rd"
