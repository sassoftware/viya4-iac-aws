# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These values MUST be provided to run Terraform commands
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
tags                                    = { } # e.g., { project_name = "sasviya4", environment = "dev", key1 = "value1", key2 ="value2"}

# These values are required to access Kubernetes cluster and run kubectl commands
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
# ****************  REQUIRED VARIABLES  ****************

## Cluster config
kubernetes_version                    = "1.18"
cluster_endpoint_public_access_cidrs  = []
tags                                  = { project_name = "viya", environment = "test-min" }

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
postgres_administrator_password       = "mySup3rS3cretPassw0rd"
