# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "prd"
location = "ap-northeast-1" # e.g., "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

#***************** CIDR Range for Spoke VPC **************

vpc_cidr     = "10.80.16.0/22"
hub          = "CustomerSpokeUS"
hub_environment = "prod"


 org_id = "o-03y3m4pkl8"
 central_restore_operator = "arn:aws:iam::992382826079:role/sascloud-awsng-central-restore-iam-role-prod"
 central_backup_operator = "arn:aws:iam::992382826079:role/sascloud-awsng-central-backup-iam-role-prod"
 central_backup_vault_us = "arn:aws:backup:us-east-1:992382826079:backup-vault:sascloud-awsng-central-backup-vault-prod"
 central_backup_vault_eu = "arn:aws:backup:eu-central-1:992382826079:backup-vault:sascloud-awsng-central-backup-vault-prod"
 central_logging_bucket =  "arn:aws:s3:::sascloud-awsng-centralized-prod-logging-bkt"  
 core_network_id = "core-network-0f5411afa03340169"
 core_network_arn = "arn:aws:networkmanager::396608809900:core-network/core-network-0f5411afa03340169"


# ********* Set to true to enable NIST complaint code ***********
enable_nist_features = true
backup_account_id = "992382826079"

#***************** Additional CIDR ranges for Spoke VPC *************

additional_cidr_ranges = ["10.88.4.0/24", "10.89.1.0/26", "10.90.0.128/27", "10.91.0.128/27"]

subnets = {
  "private" : ["10.80.16.0/23"],
  "control_plane" : ["10.90.0.128/28", "10.90.0.144/28"], # AWS recommends at least 16 IP addresses per subnet
  "public" : ["10.89.1.0/27", "10.89.1.32/27"],
  "database" : ["10.88.4.0/25", "10.88.4.128/25"],
  "eni" : ["10.91.0.128/28", "10.91.0.144/28"]
}

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
  default = {
      "storage_encrypted": true,
      "deletion_protection": true,
      "multi_az": true
},
}

## Cluster config
kubernetes_version           = "1.29"
default_nodepool_node_count  = 2
default_nodepool_vm_type     = "m5.2xlarge"
default_nodepool_custom_data = ""

## General
efs_performance_mode = "maxIO"
storage_type          = "ha"
storage_type_backend  = "ontap"
enable_efs_encryption = true

# Jump Server
create_jump_vm = true
##### NIST Enablement####

create_public_ip      = false ### Set false if enable_nist_feature is set to true
create_jump_public_ip = false ### Set false if enable_nist_feature is set to true
enable_ebs_encryption = true

#template_s3_uri       = "s3://sascloud-awsng-conformance-pack/Operational-Best-Practices-for-NIST-800-53-rev-5.yaml"
conformance_pack_name = "Operational-Best-Practices-for-NIST-800-53-rev-5"
spoke_account_id         = "296062556962"

## Cluster Node Pools config
node_pools = {
  cas = {
    "vm_type"      = "i3.8xlarge"
    "cpu_type"     = "AL2_x86_64"
    "os_disk_type" = "gp2"
    "os_disk_size" = 200
    "os_disk_iops" = 0
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "custom_data"                          = "./files/custom-data/additional_userdata.sh"
    "metadata_http_endpoint"               = "enabled"
    "metadata_http_tokens"                 = "required"
    "metadata_http_put_response_hop_limit" = 1
  },
  compute = {
    "vm_type"      = "m5.8xlarge"
    "cpu_type"     = "AL2_x86_64"
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
    "vm_type"      = "m5.4xlarge"
    "cpu_type"     = "AL2_x86_64"
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
    "vm_type"      = "m5.4xlarge"
    "cpu_type"     = "AL2_x86_64"
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
