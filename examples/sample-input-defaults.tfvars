# !NOTE! - These are only a subset of the variables in CONFIG-VARS.md provided
# as examples. Customize this file to add any variables from CONFIG-VARS.md whose
# default values you want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = []  # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# Tags for all tagable items in your cluster.
tags                                    = { } # e.g., { "key1" = "value1", "key2" = "value2" }

## General
# To enable EBS encyption - set to 'true'. Variable is set to 'false' by default.
enable_ebs_encryption = false
# To enable EFS encyption - set to 'true'. Variable is set to 'false' by default.
enable_efs_encryption = false
