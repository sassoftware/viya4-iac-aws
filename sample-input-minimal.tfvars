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
tags                                  = { project_name = "viya", environment = "test-min" }

# Jump Server
create_jump_vm                        = true

# Cloud Postgres values config
postgres_administrator_password       = "mySup3rS3cretPassw0rd"