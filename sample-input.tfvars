#!NOTE!# These are only a subset of inputs from variables.tf
# Customize this file to add any more inputs from 'variables.tf' file that you want to change
# and change the values according to your need
prefix                          = "viya-tst1"
location                        = "us-east-1"
#
# If you provide a public key this will be used for all vm's created
# If a public key is not provided as public_key will be generated along
# with it's private_key counter parts. This will also generated outpout
# for the articated associated with this key.
#
# ssh_public_key                  = "~/.ssh/id_rsa.pub"

## Cluster config
kubernetes_version                    = "1.17"
cluster_endpoint_public_access_cidrs  = []
tags                                  = { project_name = "viya", environment = "test-std" }

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
