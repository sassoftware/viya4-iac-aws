# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {

  # AWS caller user name derived from ARN value
  aws_caller_identity_name = element(split("/", data.aws_caller_identity.terraform.arn), length(split("/", data.aws_caller_identity.terraform.arn)) - 1)

  # Determine if the caller is an IAM user
  caller_is_user = strcontains(data.aws_caller_identity.terraform.arn, ":user")

  # AWS caller role name derived from ARN value
  aws_caller_role_name = local.caller_is_user ? "" : element(split("/", data.aws_caller_identity.terraform.arn), length(split("/", data.aws_caller_identity.terraform.arn)) - 2)

  # General
  # Security group ID for the instance, can be from variable or derived from existing security group
  security_group_id = var.security_group_id == null ? aws_security_group.sg[0].id : data.aws_security_group.sg[0].id
  # Cluster security group ID, with a preference for the variable value
  cluster_security_group_id = var.cluster_security_group_id == null ? aws_security_group.cluster_security_group[0].id : var.cluster_security_group_id
  # Workers security group ID, with a preference for the variable value
  workers_security_group_id = var.workers_security_group_id == null ? aws_security_group.workers_security_group[0].id : var.workers_security_group_id
  # Name of the EKS cluster
  cluster_name = "${var.prefix}-eks"
  # Default tags applied to resources
  default_tags = { project_name = "viya" }
  # Tags for the resources, defaults to project name if not provided
  tags = var.tags == null ? local.default_tags : length(var.tags) == 0 ? local.default_tags : var.tags

  # aws_shared_credentials_file - is DEPRECATED and will be removed in a future release
  # Determine if the deprecated AWS shared credentials file variable is used
  use_aws_shared_credentials_file = var.aws_shared_credentials_file != null ? length(var.aws_shared_credentials_file) > 0 ? true : false : false
  # Assign correct credential file value - If the old value is false, then new value must be used.
  # Use the deprecated AWS shared credentials file if the corresponding variable is set
  aws_shared_credentials = local.use_aws_shared_credentials_file ? [var.aws_shared_credentials_file] : var.aws_shared_credentials_files

  # CIDRs
  # Public and private access CIDRs, defaulting to empty list if not provided
  default_public_access_cidrs  = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  default_private_access_cidrs = var.default_private_access_cidrs == null ? [] : var.default_private_access_cidrs

  # VM-specific public and private access CIDRs, defaulting to the general defaults if not provided
  vm_public_access_cidrs  = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  vm_private_access_cidrs = var.vm_private_access_cidrs == null ? local.default_private_access_cidrs : var.vm_private_access_cidrs

  # Cluster endpoint access CIDRs, determined by the cluster API mode and defaulting to the general defaults if not provided
  cluster_endpoint_public_access_cidrs = var.cluster_api_mode == "private" ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)

  # Private access CIDRs for the cluster endpoint, ensuring uniqueness in the list
  cluster_endpoint_private_access_cidrs = var.cluster_endpoint_private_access_cidrs == null ? distinct(concat(module.vpc.public_subnet_cidrs, module.vpc.private_subnet_cidrs, local.default_private_access_cidrs)) : distinct(concat(module.vpc.public_subnet_cidrs, module.vpc.private_subnet_cidrs, local.default_private_access_cidrs, var.cluster_endpoint_private_access_cidrs)) # tflint-ignore: terraform_unused_declarations

  # Private access CIDRs for the VPC endpoint, ensuring uniqueness in the list
  vpc_endpoint_private_access_cidrs = var.vpc_endpoint_private_access_cidrs == null ? distinct(concat(module.vpc.public_subnet_cidrs, module.vpc.private_subnet_cidrs, local.default_private_access_cidrs)) : distinct(concat(module.vpc.public_subnet_cidrs, module.vpc.private_subnet_cidrs, local.default_private_access_cidrs, var.vpc_endpoint_private_access_cidrs))

  # Public access CIDRs for PostgreSQL, defaulting to the general public access CIDRs if not provided
  postgres_public_access_cidrs = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  # Subnets
  # Determine the subnet to use for the jump VM, based on public IP creation flag
  jump_vm_subnet = var.create_jump_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  # Determine the subnet to use for the NFS VM, based on public IP creation flag
  nfs_vm_subnet = var.create_nfs_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  # Availability zone for the NFS VM subnet, based on public IP creation flag
  nfs_vm_subnet_az = var.create_nfs_public_ip ? module.vpc.public_subnet_azs[0] : module.vpc.private_subnet_azs[0]

  # Generate list of AZ where created subnets should be placed
  # If not specified by the user replace with list of all AZs in a region
  public_subnet_azs        = can(var.subnet_azs["public"]) ? var.subnet_azs["public"] : data.aws_availability_zones.available.names
  private_subnet_azs       = can(var.subnet_azs["private"]) ? var.subnet_azs["private"] : data.aws_availability_zones.available.names
  database_subnet_azs      = can(var.subnet_azs["database"]) ? var.subnet_azs["database"] : data.aws_availability_zones.available.names
  control_plane_subnet_azs = can(var.subnet_azs["control_plane"]) ? var.subnet_azs["control_plane"] : data.aws_availability_zones.available.names

  # Read the SSH public key from the specified file
  ssh_public_key = (var.create_jump_vm || var.storage_type == "standard"
    ? file(var.ssh_public_key)
    : null
  )

  # Storage
  # Determine the backend type for storage based on the selected storage type
  storage_type_backend = (var.storage_type == "none" ? "none"
    : var.storage_type == "standard" ? "nfs"
    : var.storage_type == "ha" && var.storage_type_backend == "ontap" ? "ontap"
  : var.storage_type == "ha" ? "efs" : "none")

  # Kubernetes
  # Filename and path for the kubeconfig file
  kubeconfig_filename = "${local.cluster_name}-kubeconfig.conf"
  kubeconfig_path     = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename
  # Certificate authority data for the Kubernetes cluster
  kubeconfig_ca_cert = module.eks.cluster_certificate_authority_data

  # Mapping node_pools to node_groups
  # Default node pool configuration
  default_node_pool = {
    default = {
      name           = "default"
      instance_types = [var.default_nodepool_vm_type]
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_type = var.default_nodepool_os_disk_type
            volume_size = var.default_nodepool_os_disk_size
            iops        = var.default_nodepool_os_disk_iops
            encrypted   = var.enable_ebs_encryption
          }
        }
      }
      desired_size = var.default_nodepool_node_count
      min_size     = var.default_nodepool_min_nodes
      max_size     = var.default_nodepool_max_nodes
      # Taints for the node pool, derived from the variable configuration
      taints = { for i, taint in var.default_nodepool_taints : "default-${i}" => {
        "key"    = split("=", taint)[0],
        "value"  = split(":", split("=", taint)[1])[0],
        "effect" = length(regexall(":No", taint)) > 0 ? upper(replace(split(":", split("=", taint)[1])[1], "No", "NO_")) : upper(replace(split(":", split("=", taint)[1])[1], "No", "_NO_"))
        }
      }
      labels = var.default_nodepool_labels
      # User data for bootstrapping the node
      bootstrap_extra_args    = "--kubelet-extra-args '--node-labels=${replace(replace(jsonencode(var.default_nodepool_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", var.default_nodepool_taints)} ' "
      pre_bootstrap_user_data = (var.default_nodepool_custom_data != "" ? file(var.default_nodepool_custom_data) : "")
      metadata_options = {
        http_endpoint               = var.default_nodepool_metadata_http_endpoint
        http_tokens                 = var.default_nodepool_metadata_http_tokens
        http_put_response_hop_limit = var.default_nodepool_metadata_http_put_response_hop_limit
      }
      # Launch Template configuration
      create_launch_template          = true
      launch_template_name            = "${local.cluster_name}-default-lt"
      launch_template_use_name_prefix = true
      launch_template_tags            = { Name = "${local.cluster_name}-default" }
      tags                            = var.autoscaling_enabled ? merge(local.tags, { "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned", propagate_at_launch = true }, { "k8s.io/cluster-autoscaler/enabled" = "true", propagate_at_launch = true }) : local.tags

      # Node Pool IAM Configuration
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.prefix}-default-eks-node-group"
    }
  }

  # User-defined node pools configuration
  user_node_pool = {
    for key, np_value in var.node_pools :
    key => {
      name           = key
      instance_types = [np_value.vm_type]
      ami_type       = np_value.cpu_type
      disk_size      = np_value.os_disk_size
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_type = np_value.os_disk_type
            volume_size = np_value.os_disk_size
            iops        = np_value.os_disk_iops
            encrypted   = var.enable_ebs_encryption
          }
        }
      }
      desired_size = var.autoscaling_enabled ? np_value.min_nodes == 0 ? 1 : np_value.min_nodes : np_value.min_nodes # TODO - Remove when moving to managed nodes
      min_size     = np_value.min_nodes
      max_size     = np_value.max_nodes
      # AWS EKS Taints - https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html
      taints = { for i, taint in np_value.node_taints : "${key}-${i}" => { # to handle multiple taints, add index i to key for uniqueness
        "key"    = split("=", taint)[0],
        "value"  = split(":", split("=", taint)[1])[0],
        "effect" = length(regexall(":No", taint)) > 0 ? upper(replace(split(":", split("=", taint)[1])[1], "No", "NO_")) : upper(replace(split(":", split("=", taint)[1])[1], "No", "_NO_"))
        }
      }
      labels = np_value.node_labels
      # User data for bootstrapping the node
      bootstrap_extra_args    = "--kubelet-extra-args '--node-labels=${replace(replace(jsonencode(np_value.node_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", np_value.node_taints)}' "
      pre_bootstrap_user_data = (np_value.custom_data != "" ? file(np_value.custom_data) : "")
      metadata_options = {
        http_endpoint               = var.default_nodepool_metadata_http_endpoint
        http_tokens                 = var.default_nodepool_metadata_http_tokens
        http_put_response_hop_limit = var.default_nodepool_metadata_http_put_response_hop_limit
      }

      subnet_ids = module.vpc.private_subnets[np_value.subnet_number]
      # Launch Template configuration
      create_launch_template          = true
      launch_template_name            = "${local.cluster_name}-${key}-lt"
      launch_template_use_name_prefix = true
      launch_template_tags            = { Name = "${local.cluster_name}-${key}" }
      tags                            = var.autoscaling_enabled ? merge(local.tags, { "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned", propagate_at_launch = true }, { "k8s.io/cluster-autoscaler/enabled" = "true", propagate_at_launch = true }) : local.tags
      # Node Pool IAM Configuration
      iam_role_use_name_prefix = false
      iam_role_name            = "${var.prefix}-${key}-eks-node-group"
    }
  }

  # Merging the default_node_pool into the work_groups node pools
  # Combine the default node pool configuration with user-defined node pools
  node_groups = merge(local.default_node_pool, local.user_node_pool)

  # PostgreSQL
  # Servers configuration for PostgreSQL, merging defaults with user-provided values
  postgres_servers = var.postgres_servers == null ? {} : { for k, v in var.postgres_servers : k => merge(var.postgres_server_defaults, v, ) }
  # Extracting server ports for PostgreSQL security group rules
  postgres_sgr_ports = var.postgres_servers != null ? length(local.postgres_servers) != 0 ? [for k, v in local.postgres_servers :
    v.server_port
  ] : [] : []
  # Creating CIDR and port pairs for PostgreSQL access rules
  postgres_cidr_port_pairs = setproduct(local.postgres_sgr_ports, local.postgres_public_access_cidrs)

  # Ingress pairs for PostgreSQL, mapping server ports to CIDRs
  ingress_pairs = length(local.postgres_cidr_port_pairs) != 0 ? { for pair in local.postgres_cidr_port_pairs :
    "${pair[0]}-${pair[1]}" => {
      "server_port" : pair[0],
      "cidr" : pair[1]
    }
  } : {}


  # Outputs from the PostgreSQL module, exposing essential information
  postgres_outputs = length(module.postgresql) != 0 ? { for k, v in module.postgresql :
    k => {
      "server_name" : module.postgresql[k].db_instance_identifier,
      "fqdn" : module.postgresql[k].db_instance_address,
      "admin" : module.postgresql[k].db_instance_username,
      "password" : local.postgres_servers[k].administrator_password,
      "server_port" : module.postgresql[k].db_instance_port
      "ssl_enforcement_enabled" : local.postgres_servers[k].ssl_enforcement_enabled,
      "internal" : false
    }
  } : {}

}
