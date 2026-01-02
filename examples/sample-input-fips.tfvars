# !NOTE! - These are only a subset of CONFIG-VARS.md provided as examples.
# Customize this file to add any variables from 'CONFIG-VARS.md' whose default values you
# want to change.

# ****************  REQUIRED VARIABLES  ****************
# These required variables' values MUST be provided by the User
prefix   = "<prefix-value>" # this is a prefix that you assign for the resources to be created
location = "us-east-1"
# ****************  REQUIRED VARIABLES  ****************

# !NOTE! - Without specifying your CIDR block access rules, ingress traffic
#          to your cluster will be blocked by default.

# **************  RECOMMENDED  VARIABLES  ***************
default_public_access_cidrs = [] # e.g., ["123.45.6.89/32"]
ssh_public_key              = "~/.ssh/id_rsa.pub"
# **************  RECOMMENDED  VARIABLES  ***************

# **************  SECURITY - FIPS MODE  ***************
# Enable FIPS 140-2 for all cluster nodes
# NOTE: Only AL2023 AMI types support FIPS
# Amazon Linux 2 (AL2) does NOT have FIPS variants
fips_enabled = true
# **************  SECURITY - FIPS MODE  ***************

# Kubernetes Version
kubernetes_version = "1.32"

# Cluster API - Public or Private
cluster_api_mode = "public"

# EKS Cluster defaults - Default node pool configuration
default_nodepool_vm_type             = "m5.xlarge"
default_nodepool_os_disk_type        = "gp3"
default_nodepool_os_disk_size        = 200
default_nodepool_os_disk_iops        = 3000
default_nodepool_node_count          = 2
default_nodepool_max_nodes           = 5
default_nodepool_min_nodes           = 2
default_nodepool_taints              = []
default_nodepool_labels              = {}
default_nodepool_custom_data         = ""

# Additional Node Pools
# NOTE: Only AL2023 AMI types support FIPS
# cpu_type values below will be automatically mapped to FIPS equivalents when fips_enabled=true
node_pools = {
  cas = {
    "vm_type"      = "m5.2xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD" # Will map to AL2023_x86_64_FIPS_140_2_ENABLED
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=cas:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "cas"
    }
    "custom_data" = ""
  },
  compute = {
    "vm_type"      = "m5.8xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD" # Will map to AL2023_x86_64_FIPS_140_2_ENABLED
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=compute:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class"        = "compute"
      "launcher.sas.com/prepullImage" = "sas-programming-environment"
    }
    "custom_data" = ""
  },
  stateless = {
    "vm_type"      = "m5.4xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD" # Will map to AL2023_x86_64_FIPS_140_2_ENABLED
    "os_disk_type" = "gp3"
    "os_disk_size" = 200
    "os_disk_iops" = 3000
    "min_nodes"    = 1
    "max_nodes"    = 5
    "node_taints"  = ["workload.sas.com/class=stateless:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateless"
    }
    "custom_data" = ""
  },
  stateful = {
    "vm_type"      = "m5.4xlarge"
    "cpu_type"     = "AL2023_x86_64_STANDARD" # Will map to AL2023_x86_64_FIPS_140_2_ENABLED
    "os_disk_type" = "gp3"
    "os_disk_size" = "200"
    "os_disk_iops" = 3000
    "min_nodes"    = 1
    "max_nodes"    = 3
    "node_taints"  = ["workload.sas.com/class=stateful:NoSchedule"]
    "node_labels" = {
      "workload.sas.com/class" = "stateful"
    }
    "custom_data" = ""
  }
}

# Jump Server
create_jump_vm        = true
create_jump_public_ip = true
jump_vm_admin         = "jumpuser"
jump_vm_type          = "t3.medium"

# Storage for SAS Viya CAS/Compute
storage_type = "standard"

# NFS Server VM (only when storage_type=standard)
create_nfs_public_ip = false
nfs_vm_admin         = "nfsuser"
nfs_vm_type          = "m5.xlarge"
nfs_raid_disk_type   = "gp3"
nfs_raid_disk_size   = 256
nfs_raid_disk_iops   = 3000

# Postgres config
postgres_servers = {
  default = {},
}
