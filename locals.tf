
locals {

  # General
  security_group_id                     = var.security_group_id == null ? aws_security_group.sg[0].id : data.aws_security_group.sg[0].id
  cluster_security_group_id             = var.cluster_security_group_id == null ? aws_security_group.cluster_security_group.0.id : var.cluster_security_group_id
  workers_security_group_id             = var.workers_security_group_id == null ? aws_security_group.workers_security_group.0.id : var.workers_security_group_id
  cluster_name                          = "${var.prefix}-eks"

  # CIDRs
  default_public_access_cidrs           = var.default_public_access_cidrs == null ? [] : var.default_public_access_cidrs
  vm_public_access_cidrs                = var.vm_public_access_cidrs == null ? local.default_public_access_cidrs : var.vm_public_access_cidrs
  cluster_endpoint_public_access_cidrs  = var.cluster_api_mode == "private" ? [] : (var.cluster_endpoint_public_access_cidrs == null ? local.default_public_access_cidrs : var.cluster_endpoint_public_access_cidrs)
  cluster_endpoint_private_access_cidrs = var.cluster_endpoint_private_access_cidrs == null ? distinct(concat(module.vpc.public_subnet_cidrs, module.vpc.private_subnet_cidrs)) : var.cluster_endpoint_private_access_cidrs
  postgres_public_access_cidrs          = var.postgres_public_access_cidrs == null ? local.default_public_access_cidrs : var.postgres_public_access_cidrs

  # Subnets
  jump_vm_subnet                        = var.create_jump_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  nfs_vm_subnet                         = var.create_nfs_public_ip ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]
  nfs_vm_subnet_az                      = var.create_nfs_public_ip ? module.vpc.public_subnet_azs[0] : module.vpc.private_subnet_azs[0]

  ssh_public_key = ( var.create_jump_vm || var.storage_type == "standard"
                     ? file(var.ssh_public_key)
                     : null
                   )


  # Kubernetes
  kubeconfig_filename                   = "${local.cluster_name}-kubeconfig.conf"
  kubeconfig_path                       = var.iac_tooling == "docker" ? "/workspace/${local.kubeconfig_filename}" : local.kubeconfig_filename
  kubeconfig_ca_cert                    = data.aws_eks_cluster.cluster.certificate_authority.0.data

  # Mapping node_pools to node_groups
  default_node_pool = {
    default = {
      name                              = "default"
      instance_types                     = [var.default_nodepool_vm_type]
      block_device_mappings           = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_type                     = var.default_nodepool_os_disk_type
            volume_size                     = var.default_nodepool_os_disk_size
            iops                            = var.default_nodepool_os_disk_iops
          }
        }
      }
      desired_size                      = var.default_nodepool_node_count
      min_size                          = var.default_nodepool_min_nodes
      max_size                          = var.default_nodepool_max_nodes
      taints                            = { for i, taint in var.default_nodepool_taints : "default-${i}"=> { 
                                              "key" = split("=", taint)[0], 
                                              "value"= split(":", split("=", taint)[1])[0], 
                                              "effect"=length(regexall(":No", taint)) > 0 ? upper(replace(split(":", split("=", taint)[1])[1], "No", "NO_")) : upper(replace(split(":", split("=", taint)[1])[1], "No", "_NO_"))
                                            } 
                                          }
      labels                            = var.default_nodepool_labels
      # User data
      bootstrap_extra_args              = "--kubelet-extra-args '--node-labels=${replace(replace(jsonencode(var.default_nodepool_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", var.default_nodepool_taints)} ' "
      post_bootstrap_user_data          = (var.default_nodepool_custom_data != "" ? file(var.default_nodepool_custom_data) : "")
      metadata_options                  = { 
          http_endpoint                 = var.default_nodepool_metadata_http_endpoint
          http_tokens                   = var.default_nodepool_metadata_http_tokens
          http_put_response_hop_limit   = var.default_nodepool_metadata_http_put_response_hop_limit
      }
      # Launch Template
      create_launch_template          = true
      launch_template_name            = "${local.cluster_name}-default-lt"
      launch_template_use_name_prefix = true
      tags                            = var.autoscaling_enabled ? merge(var.tags, { key = "k8s.io/cluster-autoscaler/${local.cluster_name}", value = "owned", propagate_at_launch = true }, { key = "k8s.io/cluster-autoscaler/enabled", value = "true", propagate_at_launch = true}) : var.tags
    }
  }

  user_node_pool = {
    for key, np_value in var.node_pools :
      key => {
        name                            = key
        instance_types                   = [np_value.vm_type]
        disk_size                       = np_value.os_disk_size
        block_device_mappings           = {
          xvda = {
            device_name = "/dev/xvda"
            ebs = {
              volume_type                   = np_value.os_disk_type
              volume_size                   = np_value.os_disk_size
              iops                          = np_value.os_disk_iops
            }
          }
        }
        desired_size                    = var.autoscaling_enabled ? np_value.min_nodes == 0 ? 1 : np_value.min_nodes : np_value.min_nodes # TODO - Remove when moving to managed nodes
        min_size                        = np_value.min_nodes
        max_size                        = np_value.max_nodes
        # AWS EKS Taints - https://docs.aws.amazon.com/eks/latest/userguide/node-taints-managed-node-groups.html
        taints                          ={ for i, taint in np_value.node_taints: "${key}-${i}"=> {   # to handle multiple taints, add index i to key for uniqueness
                                              "key" = split("=", taint)[0], 
                                              "value"= split(":", split("=", taint)[1])[0], 
                                              "effect"=length(regexall(":No", taint)) > 0 ? upper(replace(split(":", split("=", taint)[1])[1], "No", "NO_")) : upper(replace(split(":", split("=", taint)[1])[1], "No", "_NO_"))
                                            } 
                                          }
        labels                          = np_value.node_labels
        # User data
        bootstrap_extra_args            = "--kubelet-extra-args '--node-labels=${replace(replace(jsonencode(np_value.node_labels), "/[\"\\{\\}]/", ""), ":", "=")} --register-with-taints=${join(",", np_value.node_taints)}' "
        post_bootstrap_user_data        = (np_value.custom_data != "" ? file(np_value.custom_data) : "")
        metadata_options                = { 
            http_endpoint               = var.default_nodepool_metadata_http_endpoint
            http_tokens                 = var.default_nodepool_metadata_http_tokens
            http_put_response_hop_limit = var.default_nodepool_metadata_http_put_response_hop_limit
        }
        # Launch Template
        create_launch_template          = true
        launch_template_name            = "${local.cluster_name}-${key}-lt"
        launch_template_use_name_prefix = true
        tags                            = var.autoscaling_enabled ? merge(var.tags, { key = "k8s.io/cluster-autoscaler/${local.cluster_name}", value = "owned", propagate_at_launch = true }, { key = "k8s.io/cluster-autoscaler/enabled", value = "true", propagate_at_launch = true}) : var.tags
      }
  }

  # Merging the default_node_pool into the work_groups node pools
  node_groups = merge(local.default_node_pool, local.user_node_pool)

  # PostgreSQL
  postgres_servers    = var.postgres_servers == null ? {} : { for k, v in var.postgres_servers : k => merge( var.postgres_server_defaults, v, )}
  postgres_sgr_ports  = var.postgres_servers != null ? length(local.postgres_servers) != 0 ? [ for k,v in local.postgres_servers :
      v.server_port
  ] : [] : null

  postgres_outputs    = length(module.postgresql) != 0 ? { for k,v in module.postgresql :
    k => {
      "server_name" : module.postgresql[k].db_instance_id,
      "fqdn" : module.postgresql[k].db_instance_address,
      "admin" : module.postgresql[k].db_instance_username,
      "password" : module.postgresql[k].db_instance_password,
      "server_port" : module.postgresql[k].db_instance_port 
      "ssl_enforcement_enabled" : local.postgres_servers[k].ssl_enforcement_enabled,
      "internal" : false
    }
  } : {}

}
