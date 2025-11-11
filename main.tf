# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

## AWS-EKS
#
# Terraform Registry : https://registry.terraform.io/namespaces/terraform-aws-modules
# GitHub Repository  : https://github.com/terraform-aws-modules
#

# Provider block for AWS. Configures the AWS provider with region, profile, credentials, and session token.
provider "aws" {
  region                   = var.location                 # AWS region to deploy resources (see variables.tf: location)
  profile                  = var.aws_profile              # AWS CLI profile to use (see variables.tf: aws_profile)
  shared_credentials_files = local.aws_shared_credentials # List of shared credentials files (see locals.tf: aws_shared_credentials)
  access_key               = var.aws_access_key_id        # AWS access key (see variables.tf: aws_access_key_id)
  secret_key               = var.aws_secret_access_key    # AWS secret key (see variables.tf: aws_secret_access_key)
  token                    = var.aws_session_token        # AWS session token for temporary credentials (see variables.tf: aws_session_token)
}

# Data source to get authentication token for EKS cluster. Used by the Kubernetes provider.
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name # Name of the EKS cluster (from module.eks)
}

# Data source to get all available AWS availability zones in the selected region.
data "aws_availability_zones" "available" {}

# Data source to get information about the current AWS caller identity (account, user, etc).
data "aws_caller_identity" "terraform" {}

# Data source to get the current git commit hash for build info. Uses an external script.
data "external" "git_hash" {
  program = ["files/tools/iac_git_info.sh"]
}

# Data source to get the current IAC tooling version and provider info. Uses an external script.
data "external" "iac_tooling_version" {
  program = ["files/tools/iac_tooling_version.sh"]
}

# Resource to create a Kubernetes ConfigMap in the kube-system namespace with build info (git hash, timestamp, tooling version, etc).
resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }
  data = {
    git-hash    = data.external.git_hash.result["git-hash"] # Current git commit hash
    timestamp   = chomp(timestamp())                        # Current timestamp
    iac-tooling = var.iac_tooling                           # Tooling identifier (see variables.tf: iac_tooling)
    terraform   = <<EOT
version: ${data.external.iac_tooling_version.result["terraform_version"]}
revision: ${data.external.iac_tooling_version.result["terraform_revision"]}
provider-selections: ${data.external.iac_tooling_version.result["provider_selections"]}
outdated: ${data.external.iac_tooling_version.result["terraform_outdated"]}
EOT
  }
  depends_on = [module.kubeconfig.kube_config] # Wait for kubeconfig to be ready
}

# Provider block for Kubernetes. Configures the Kubernetes provider to connect to the EKS cluster using the generated kubeconfig and token.
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint             # EKS API endpoint
  cluster_ca_certificate = base64decode(local.kubeconfig_ca_cert)  # Cluster CA cert (from locals.tf)
  token                  = data.aws_eks_cluster_auth.cluster.token # Auth token for EKS
}

# Provider block for Helm. Configures the Helm provider to connect to the EKS cluster using the same configuration as Kubernetes provider.
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint             # EKS API endpoint
    cluster_ca_certificate = base64decode(local.kubeconfig_ca_cert)  # Cluster CA cert (from locals.tf)
    token                  = data.aws_eks_cluster_auth.cluster.token # Auth token for EKS
  }
}

# VPC Setup
module "vpc" {
  source = "./modules/aws_vpc"

  name                          = var.prefix                        # Resource name prefix
  vpc_id                        = var.vpc_id                        # Use existing VPC if provided
  region                        = var.location                      # AWS region
  security_group_id             = local.security_group_id           # Main security group
  raw_sec_group_id              = var.security_group_id             # Raw input security group
  cluster_security_group_id     = var.cluster_security_group_id     # EKS cluster security group
  workers_security_group_id     = var.workers_security_group_id     # Node group security group
  cidr                          = var.vpc_cidr                      # VPC CIDR block
  enable_ipv6                   = var.enable_ipv6
  public_subnet_azs             = local.public_subnet_azs           # AZs for public subnets
  private_subnet_azs            = local.private_subnet_azs          # AZs for private subnets
  database_subnet_azs           = local.database_subnet_azs         # AZs for database subnets
  control_plane_subnet_azs      = local.control_plane_subnet_azs    # AZs for control plane subnets
  existing_subnet_ids           = var.subnet_ids                    # Use existing subnets if provided
  subnets                       = var.subnets                       # Subnet CIDRs to create
  existing_nat_id               = var.nat_id                        # Use existing NAT Gateway if provided
  vpc_private_endpoints_enabled = var.vpc_private_endpoints_enabled # Enable VPC endpoints

  tags                = local.tags                                                                                                                   # Common tags
  public_subnet_tags  = merge(local.tags, { "kubernetes.io/role/elb" = "1" }, { "kubernetes.io/cluster/${local.cluster_name}" = "shared" })          # Tags for public subnets
  private_subnet_tags = merge(local.tags, { "kubernetes.io/role/internal-elb" = "1" }, { "kubernetes.io/cluster/${local.cluster_name}" = "shared" }) # Tags for private subnets
}

# EKS Setup - https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source                               = "terraform-aws-modules/eks/aws"
  version                              = "~> 20.0"
  cluster_name                         = local.cluster_name                                                         # EKS cluster name
  cluster_version                      = var.kubernetes_version                                                     # Kubernetes version
  cluster_enabled_log_types            = var.cluster_enabled_log_types == null ? [] : var.cluster_enabled_log_types # EKS audit log types
  create_cloudwatch_log_group          = var.cluster_enabled_log_types == null ? false : true                       # Create CloudWatch log group if logging enabled
  cluster_endpoint_private_access      = true                                                                       # Always enable private endpoint
  cluster_endpoint_public_access       = var.cluster_api_mode == "public" ? true : false                            # Enable public endpoint if requested
  cluster_endpoint_public_access_cidrs = local.cluster_endpoint_public_access_cidrs                                 # CIDRs allowed for public endpoint
  cluster_ip_family                    = var.enable_ipv6 ? "ipv6" : "ipv4"  # IPv6 pods when IPv6 is enabled, IPv4 otherwise

  # AWS requires two or more subnets in different Availability Zones for your cluster's control plane.
  control_plane_subnet_ids = module.vpc.control_plane_subnets # Subnets for EKS control plane
  # Specifies the list of subnets in which the worker nodes of the EKS cluster will be launched.
  subnet_ids  = module.vpc.private_subnets # Subnets for worker nodes
  vpc_id      = module.vpc.vpc_id          # VPC ID
  tags        = local.tags                 # Common tags
  enable_irsa = var.autoscaling_enabled    # Enable IAM Roles for Service Accounts if autoscaling
  ################################################################################
  # Cluster Security Group
  ################################################################################
  create_cluster_security_group = false                           # Use custom security group
  cluster_security_group_id     = local.cluster_security_group_id # Security group for EKS control plane
  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  ################################################################################
  # Node Security Group
  ################################################################################
  create_node_security_group = false                           # Use custom node security group
  node_security_group_id     = local.workers_security_group_id # Security group for nodes
  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
  # We already set our own rules above, no need to use Amazon's defaults.
  node_security_group_enable_recommended_rules = false

  # enabled by default in v19, setting to false to preserve original behavior.
  create_kms_key            = false # Do not create KMS key
  cluster_encryption_config = []    # No encryption config

  ################################################################################
  # Handle BYO IAM Roles & Policies
  ################################################################################
  # BYO - EKS Cluster IAM Role
  create_iam_role = var.cluster_iam_role_arn == null ? true : false # Create IAM role if not provided
  iam_role_arn    = var.cluster_iam_role_arn                        # Use provided IAM role if any

  authentication_mode = var.authentication_mode # EKS authentication mode

  # Create access entry for current caller identity as a cluster admin
  enable_cluster_creator_admin_permissions = true

  iam_role_additional_policies = {
    "additional" : "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  create_cni_ipv6_iam_policy = var.enable_ipv6

  ## Use this to define any values that are common and applicable to all Node Groups
  eks_managed_node_group_defaults = {
    create_security_group  = false
    vpc_security_group_ids = [local.workers_security_group_id]

    # BYO - EKS Workers IAM Role
    create_iam_role = var.workers_iam_role_arn == null ? true : false
    iam_role_arn    = var.workers_iam_role_arn
  }

  ## Any individual Node Group customizations should go here
  eks_managed_node_groups = local.node_groups # Node group definitions (from locals)
}

# Resource to create EKS access entries for admin IAM roles. Used for EKS RBAC.
resource "aws_eks_access_entry" "instance" {
  for_each = toset(coalesce(var.admin_access_entry_role_arns, []))

  cluster_name  = module.eks.cluster_name # EKS cluster name
  principal_arn = each.value              # IAM role ARN
  type          = "STANDARD"              # Access entry type
}

# Resource to associate EKS access policy with access entries. Grants admin access to cluster.
resource "aws_eks_access_policy_association" "cluster_assoc" {
  for_each = aws_eks_access_entry.instance

  cluster_name  = module.eks.cluster_name                                              # EKS cluster name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" # Admin policy
  principal_arn = each.value.principal_arn                                             # IAM role ARN

  access_scope {
    type = "cluster" # Scope: entire cluster
  }
}

# autoscaling - Resource to create EKS access entries for user IAM roles. Used for EKS RBAC.
# This module creates the necessary IAM roles, policies, and Kubernetes resources for EKS autoscaling.
module "autoscaling" {
  source = "./modules/aws_autoscaling"
  count  = var.autoscaling_enabled ? 1 : 0

  prefix       = var.prefix                         # Resource name prefix
  cluster_name = local.cluster_name                 # EKS cluster name
  tags         = local.tags                         # Common tags
  oidc_url     = module.eks.cluster_oidc_issuer_url # OIDC issuer URL for IRSA
}

# ebs - Resource to create EBS CSI driver for EKS. Used for dynamic volume provisioning.
# This module creates the necessary IAM roles, policies, and Kubernetes resources for EBS CSI.
module "ebs" {
  source  = "./modules/aws_ebs_csi"

  prefix       = var.prefix                         # Resource name prefix
  cluster_name = local.cluster_name                 # EKS cluster name
  tags         = local.tags                         # Common tags
  oidc_url     = module.eks.cluster_oidc_issuer_url # OIDC issuer URL for IRSA
}

# ontap - Resource to create FSx for ONTAP file system. Used for shared storage.
# This module creates the necessary IAM roles, policies, and Kubernetes resources for FSx ONTAP.
module "ontap" {
  source  = "./modules/aws_fsx_ontap"
  count  = var.storage_type_backend == "ontap" ? 1 : 0

  prefix        = var.prefix                     # Resource name prefix
  tags          = local.tags                     # Common tags
  iam_user_name = local.aws_caller_identity_name # IAM user name
  is_user       = local.caller_is_user           # Whether caller is a user
  iam_role_name = local.aws_caller_role_name     # IAM role name
}

# kubeconfig - generate kubeconfig for EKS cluster. Used to access the cluster using kubectl.
module "kubeconfig" {
  source                   = "./modules/kubeconfig"
  prefix                   = var.prefix                   # Resource name prefix
  create_static_kubeconfig = var.create_static_kubeconfig # Whether to create a static kubeconfig
  path                     = local.kubeconfig_path        # Path to kubeconfig file
  namespace                = "kube-system"                # Namespace for service account

  cluster_name = local.cluster_name              # EKS cluster name
  region       = var.location                    # AWS region
  endpoint     = module.eks.cluster_endpoint     # EKS API endpoint
  ca_crt       = local.kubeconfig_ca_cert        # Cluster CA cert
  sg_id        = local.cluster_security_group_id # Security group for API access

  depends_on = [module.eks] # Wait for EKS cluster to be ready
}

# Normally, the use of local-exec below is avoided. It is used here to patch the gp2 storage class as the default storage class for EKS 1.30 and later clusters.
# PSKD-667 will track the move to a newer version of the aws-ebs-csi-driver creating a gp3 storage class which will then become the default storage class.
resource "terraform_data" "run_command" {
  count = var.kubernetes_version >= "1.30" ? 1 : 0
  provisioner "local-exec" {
    command = "kubectl --kubeconfig=${local.kubeconfig_path} patch storageclass gp2 --patch '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"true\"}}}' "
  }

  depends_on = [module.kubeconfig.kube_config] # Wait for kubeconfig
}

# Database Setup - https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/6.2.0
module "postgresql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  for_each = local.postgres_servers != null ? length(local.postgres_servers) != 0 ? local.postgres_servers : {} : {}

  identifier = lower("${var.prefix}-${each.key}-pgsql") # RDS instance identifier

  engine            = "postgres"                   # Database engine
  engine_version    = each.value.server_version    # Postgres version
  instance_class    = each.value.instance_type     # Instance type
  allocated_storage = each.value.storage_size      # Storage size (GB)
  storage_encrypted = each.value.storage_encrypted # Enable storage encryption

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = each.value.administrator_login    # DB admin username
  password = each.value.administrator_password # DB admin password
  port     = each.value.server_port            # DB port

  vpc_security_group_ids = [local.security_group_id, local.workers_security_group_id] # Security groups

  maintenance_window = "Mon:00:00-Mon:03:00" # Maintenance window
  backup_window      = "03:00-06:00"         # Backup window

  # disable backups to create DB faster
  backup_retention_period = each.value.backup_retention_days # Backup retention (days)

  tags = local.tags # Common tags

  # DB subnet group - use public subnet if public access is requested
  publicly_accessible = length(local.postgres_public_access_cidrs) > 0 ? true : false
  subnet_ids          = length(local.postgres_public_access_cidrs) > 0 ? length(module.vpc.public_subnets) > 0 ? module.vpc.public_subnets : module.vpc.database_subnets : module.vpc.database_subnets # Subnets for DB

  # DB parameter group
  family = "postgres${each.value.server_version}" # Parameter group family

  # DB option group
  major_engine_version = each.value.server_version # Option group version

  # Database Deletion Protection
  deletion_protection = each.value.deletion_protection # Enable deletion protection

  multi_az = each.value.multi_az # Enable Multi-AZ

  parameters = each.value.ssl_enforcement_enabled ? concat(each.value.parameters, [{ "apply_method" : "immediate", "name" : "rds.force_ssl", "value" : "1" }]) : concat(each.value.parameters, [{ "apply_method" : "immediate", "name" : "rds.force_ssl", "value" : "0" }]) # SSL enforcement
  options    = each.value.options                                                                                                                                                                                                                                           # Additional options

  # Flags for module to flag if postgres should be created or not.
  create_db_instance          = true  # Always create DB instance
  create_db_subnet_group      = true  # Always create subnet group
  create_db_parameter_group   = true  # Always create parameter group
  create_db_option_group      = true  # Always create option group
  manage_master_user_password = false # Do not manage master password
}

# Resource Groups - https://www.terraform.io/docs/providers/aws/r/resourcegroups_group.html
resource "aws_resourcegroups_group" "aws_rg" {
  name = "${var.prefix}-rg" # Resource group name

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": ${jsonencode([
    for key, values in local.tags : {
      "Key" : key,
      "Values" : [values]
    }
])}
}
JSON
}
}

# AWS Load Balancer Controller Setup
module "lb_controller" {
  source                  = "./modules/aws_lb_controller"
  cluster_name            = local.cluster_name
  region                  = var.location
  vpc_id                  = module.vpc.vpc_id
  controller_version      = var.lb_controller_version
  cert_manager_version    = var.cert_manager_version
  kubeconfig_depends_on   = module.kubeconfig.kube_config
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  count                   = var.enable_ipv6 ? 1 : 0
}

# Example variable definitions (add to variables.tf or root module):
# variable "lb_controller_version" {
#   description = "AWS Load Balancer Controller Helm chart version"
#   type        = string
#   default     = "1.6.2"
# }
# variable "cert_manager_version" {
#   description = "Cert Manager Helm chart version"
#   type        = string
#   default     = "v1.13.2"
# }
