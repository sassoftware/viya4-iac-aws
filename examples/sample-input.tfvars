# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These values MUST be provided to run Terraform commands
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

# These values are required to access Kubernetes cluster and run kubectl commands
cluster_endpoint_public_access_cidrs    = []  # e.g., ["123.45.6.89/32"]
# ****************  REQUIRED VARIABLES  ****************

# When a ssh key value is provided it will be used for all VMs or else a ssh key will be auto generated and available in outputs
ssh_public_key                  = "~/.ssh/id_rsa.pub"

## Cluster config
kubernetes_version                    = "1.17"

## Cluster Node Pools config

# default
create_default_nodepool               = true
default_nodepool_initial_node_count   = 1
default_nodepool_min_nodes            = 1
default_nodepool_max_nodes            = 5
default_nodepool_vm_type              = "m5.2xlarge"
default_nodepool_taints               = []
default_nodepool_labels               = []

# cas
create_cas_nodepool                   = true
cas_nodepool_initial_node_count       = 1
cas_nodepool_min_nodes                = 1
cas_nodepool_max_nodes                = 5
cas_nodepool_vm_type                  = "m5.8xlarge"
cas_nodepool_taints                   = ["workload.sas.com/class=cas:NoSchedule"]
cas_nodepool_labels                   = ["workload.sas.com/class=cas"]

# compute
create_compute_nodepool               = true
compute_nodepool_initial_node_count   = 1
compute_nodepool_min_nodes            = 1
compute_nodepool_max_nodes            = 5
compute_nodepool_vm_type              = "m5.8xlarge"
compute_nodepool_taints               = ["workload.sas.com/class=cas:NoSchedule"]
compute_nodepool_labels               = ["workload.sas.com/class=compute"]

# stateless
create_stateless_nodepool             = true
stateless_nodepool_initial_node_count = 1
stateless_nodepool_min_nodes          = 1
stateless_nodepool_max_nodes          = 5
stateless_nodepool_vm_type            = "m5.4xlarge"
stateless_nodepool_taints             = ["workload.sas.com/class=stateless:NoSchedule"]
stateless_nodepool_labels             = ["workload.sas.com/class=stateless"]

# stateful
create_stateful_nodepool              = true
stateful_nodepool_initial_node_count  = 1
stateful_nodepool_min_nodes           = 1
stateful_nodepool_max_nodes           = 3
stateful_nodepool_vm_type             = "m5.2xlarge"
stateful_nodepool_taints              = ["workload.sas.com/class=stateful:NoSchedule"]
stateful_nodepool_labels              = ["workload.sas.com/class=stateful"]

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
create_postgres                       = true # set this to "false" when using internal Crunchy Postgres and AWS Postgres is NOT needed
postgres_administrator_password       = "mySup3rS3cretPassw0rd"

# Cloud Container Registry
create_container_registry             = false
