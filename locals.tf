locals {

  # General
  security_group_id                     = var.security_group_id == null ? aws_security_group.sg[0].id : data.aws_security_group.sg[0].id
  cluster_name                          = "${var.prefix}-eks"

  # Infrastructure Mode
  is_standard                           = var.infra_mode == "standard" ? true : false
  is_private                            = var.infra_mode == "private" ? true : false

  # CIDRs
  default_public_access_cidrs           = local.is_private ? [] : (var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs)
  vm_public_access_cidrs                = local.is_private ? [] : (var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs)
  cluster_endpoint_public_access_cidrs  = local.is_private ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)
  cluster_endpoint_private_access_cidrs = var.cluster_endpoint_private_access_cidrs == null ? [var.vpc_cidr] : var.cluster_endpoint_private_access_cidrs
  postgres_public_access_cidrs          = local.is_private ? [] : (var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs)

  # IPs
  create_jump_public_ip                 = var.create_jump_public_ip == null ? local.is_standard : var.create_jump_public_ip
  create_nfs_public_ip                  = var.create_nfs_public_ip == null ? local.is_standard : var.create_nfs_public_ip

  # Subnets
  jump_vm_subnet                        = local.create_jump_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  nfs_vm_subnet                         = local.create_nfs_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  nfs_vm_subnet_az                      = local.create_nfs_public_ip ? module.vpc.public_subnet_azs[0] : module.vpc.private_subnet_azs[0]

  # Kubernetes
  kubeconfig_filename                   = "${local.cluster_name}-kubeconfig.conf"
  kubeconfig_path                       = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename
  kubeconfig_ca_cert                    = data.aws_eks_cluster.cluster.certificate_authority.0.data

  # Mapping node_pools to worker_groups
  default_node_pool = [
    {
      name                                 = "default"
      instance_type                        = var.default_nodepool_vm_type
      root_volume_size                     = var.default_nodepool_os_disk_size
      root_volume_type                     = var.default_nodepool_os_disk_type
      root_iops                            = var.default_nodepool_os_disk_iops
      asg_desired_capacity                 = var.default_nodepool_node_count
      asg_min_size                         = var.default_nodepool_min_nodes
      asg_max_size                         = var.default_nodepool_max_nodes
      kubelet_extra_args                   = "--node-labels=${replace(replace(jsonencode(var.default_nodepool_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", var.default_nodepool_taints)}"
      additional_userdata                  = (var.default_nodepool_custom_data != "" ? file(var.default_nodepool_custom_data) : "")
      metadata_http_endpoint               = var.default_nodepool_metadata_http_endpoint
      metadata_http_tokens                 = var.default_nodepool_metadata_http_tokens
      metadata_http_put_response_hop_limit = var.default_nodepool_metadata_http_put_response_hop_limit

    }
  ]

  user_node_pool = [
    for np_key, np_value in var.node_pools :
      {
        name                                 = np_key
        instance_type                        = np_value.vm_type
        root_volume_size                     = np_value.os_disk_size
        root_volume_type                     = np_value.os_disk_type
        root_iops                            = np_value.os_disk_iops
        asg_desired_capacity                 = var.autoscaling_enabled ? np_value.min_nodes == 0 ? 1 : np_value.min_nodes : np_value.min_nodes # TODO - Remove when moving to managed nodes
        asg_min_size                         = np_value.min_nodes
        asg_max_size                         = np_value.max_nodes
        kubelet_extra_args                   = "--node-labels=${replace(replace(jsonencode(np_value.node_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", np_value.node_taints)}"
        additional_userdata                  = (np_value.custom_data != "" ? file(np_value.custom_data) : "")
        metadata_http_endpoint               = np_value.metadata_http_endpoint
        metadata_http_tokens                 = np_value.metadata_http_tokens
        metadata_http_put_response_hop_limit = np_value.metadata_http_put_response_hop_limit
      }
  ]

  # Merging the default_node_pool into the work_groups node pools
  worker_groups = concat(local.default_node_pool, local.user_node_pool)

  # Postgres options/parameters
  postgres_options    = var.create_postgres ? var.postgres_options : null
  postgres_parameters = var.create_postgres ? var.postgres_ssl_enforcement_enabled ? concat(var.postgres_parameters, [{ "apply_method": "immediate", "name": "rds.force_ssl", "value": "1" }]) : concat(var.postgres_parameters, [{ "apply_method": "immediate", "name": "rds.force_ssl", "value": "0" }]) : null

}
