# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kube_config" {
  value     = module.kubeconfig.kube_config
  sensitive = true
}

output "cluster_iam_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster."
  value = (module.eks.cluster_iam_role_arn == var.cluster_iam_role_arn
    ? false
    : var.cluster_iam_role_arn
  )
}

output "workers_iam_role_arn" {
  description = "The ARN of the IAM role for the Node VMs."
  value       = var.workers_iam_role_arn
}

output "rwx_filestore_id" {
  value = (var.storage_type == "ha" && local.storage_type_backend == "efs"
    ? aws_efs_file_system.efs-fs[0].id
  : var.storage_type == "ha" && local.storage_type_backend == "ontap" ? aws_fsx_ontap_file_system.ontap-fs[0].id : null)
}

output "rwx_filestore_endpoint" {
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" && local.storage_type_backend == "efs" ? aws_efs_file_system.efs-fs[0].dns_name
    : var.storage_type == "ha" && local.storage_type_backend == "ontap" ? aws_fsx_ontap_storage_virtual_machine.ontap-svm[0].endpoints[0]["nfs"][0]["dns_name"] : module.nfs[0].private_dns
  )
}

output "rwx_filestore_path" {
  value = (var.storage_type == "none"
    ? null
    : local.storage_type_backend == "efs" ? "/"
    : local.storage_type_backend == "ontap" ? "/ontap" : "/export"
  )
}

output "efs_arn" {
  value = var.storage_type == "ha" && local.storage_type_backend == "efs" ? aws_efs_file_system.efs-fs[0].arn : null
}

output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump[0].private_ip_address : null
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump[0].public_ip_address : null
}

output "jump_admin_username" {
  value = var.create_jump_vm ? module.jump[0].admin_username : null
}

output "jump_private_dns" {
  value = var.create_jump_vm ? module.jump[0].private_dns : null
}

output "jump_public_dns" {
  value = var.create_jump_vm ? module.jump[0].public_dns : null
}

output "jump_rwx_filestore_path" {
  value = (var.storage_type != "none"
    ? var.create_jump_vm ? var.jump_rwx_filestore_path : null
    : null
  )
}

output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs[0].private_ip_address : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" ? module.nfs[0].public_ip_address : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs[0].admin_username : null
}

output "nfs_private_dns" {
  value = var.storage_type == "standard" ? module.nfs[0].private_dns : null
}

output "nfs_public_dns" {
  value = var.storage_type == "standard" ? module.nfs[0].public_dns : null
}

#postgres
output "postgres_servers" {
  value     = length(module.postgresql) != 0 ? local.postgres_outputs : null
  sensitive = true
}

output "nat_ip" {
  value = module.vpc.create_nat_gateway ? module.vpc.nat_public_ips[0] : null
}

output "prefix" {
  value = var.prefix
}

output "cluster_name" {
  value = local.cluster_name
}

output "provider" {
  value = "aws"
}

output "location" {
  value = var.location
}

## Reference for Amazon ECR private registries: https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html
output "cr_endpoint" {
  value = "https://${data.aws_caller_identity.terraform.account_id}.dkr.ecr.${var.location}.amazonaws.com"
}

output "cluster_node_pool_mode" {
  value = var.cluster_node_pool_mode
}

output "autoscaler_account" {
  value = var.autoscaling_enabled ? module.autoscaling[0].autoscaler_account : null
}

output "cluster_api_mode" {
  value = var.cluster_api_mode
}

output "ebs_csi_account" {
  value = module.ebs.ebs_csi_account
}

output "k8s_version" {
  value = module.eks.cluster_version
}

output "aws_shared_credentials_file" {
  value = var.aws_shared_credentials_file
  precondition {
    condition     = var.aws_shared_credentials_file != null
    error_message = "aws_shared_credentials_file must not be null. aws_shared_credentials_file has been deprecated and will be removed in a future release, use aws_shared_credentials_files instead."
  }
}

output "aws_shared_credentials" {
  value = local.aws_shared_credentials
  precondition {
    condition     = length(var.aws_shared_credentials_file) == 0 || var.aws_shared_credentials_files == null
    error_message = "Set either aws_shared_credentials_files or aws_shared_credentials_file, but not both. aws_shared_credentials_file is deprecated and will be removed in a future release, use aws_shared_credentials_files instead."
  }
}

output "storage_type_backend" {
  value = local.storage_type_backend != null ? local.storage_type_backend : null
  precondition {
    condition = (var.storage_type == "standard" && var.storage_type_backend == "nfs"
      || var.storage_type == "ha" && var.storage_type_backend == "nfs"
      || var.storage_type == "ha" && var.storage_type_backend == "efs"
      || var.storage_type == "ha" && var.storage_type_backend == "ontap"
    || var.storage_type == "none" && var.storage_type_backend == "none")
    error_message = "nfs is the only valid storage_type_backend when storage_type == 'standard'"
  }
}

output "aws_fsx_ontap_fsxadmin_password" {
  value     = (local.storage_type_backend == "ontap" ? var.aws_fsx_ontap_fsxadmin_password : null)
  sensitive = true
}

output "byo_network_scenario" {
  value = module.vpc.byon_scenario
}

output "validate_subnet_azs" {
  # validation, no output value needed
  value = null
  precondition {
    # Validation Notes:
    # Either the user does not define subnet_azs and it defaults to {}, in which case the whole map will be populated
    # If the user does not define a specific key, that is allowed and we will populate the az list for that subnet
    # Lastly, if the user does define a specific subnet_azs key, it must be greater than or equal to the matching subnet map list
    condition = (var.subnet_azs == {} ||
      (
        (length(lookup(var.subnet_azs, "private", [])) == 0 || length(lookup(var.subnet_azs, "private", [])) >= length(lookup(var.subnets, "private", []))) &&
        (length(lookup(var.subnet_azs, "control_plane", [])) == 0 || length(lookup(var.subnet_azs, "control_plane", [])) >= length(lookup(var.subnets, "control_plane", []))) &&
        (length(lookup(var.subnet_azs, "public", [])) == 0 || length(lookup(var.subnet_azs, "public", [])) >= length(lookup(var.subnets, "public", []))) &&
        (length(lookup(var.subnet_azs, "database", [])) == 0 || length(lookup(var.subnet_azs, "database", [])) >= length(lookup(var.subnets, "database", [])))
      )
    )
    error_message = "Your subnet_azs keys must have a string list value of AZs greater than or equal to the list of CIDRs in equivalent key in the subnets variable."
  }
}
