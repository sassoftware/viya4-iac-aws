# !NOTE! - These are only a subset of variables.tf provided for sample.
# Customize this file to add any variables from 'variables.tf' that you want 
# to change their default values. 

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix                                  = "<prefix-value>"
location                                = "<aws-location-value>" # e.g., "us-east-1"
default_public_access_cidrs             = []  # e.g., ["123.45.6.89/32"]
tags                                    = { } # e.g., { project_name = "sasviya4", environment = "dev", key1 = "value1", key2 ="value2"}
# ****************  REQUIRED VARIABLES  ****************
