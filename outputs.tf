# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kube_config" {
  description = "Kubernetes cluster authentication information for kubectl."
  value       = module.kubeconfig.kube_config
  sensitive   = true
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
  description = "The ID that identifies the file system."
  value       = (var.storage_type == "ha" && local.storage_type_backend == "efs"
    ? aws_efs_file_system.efs-fs[0].id
  : var.storage_type == "ha" && local.storage_type_backend == "ontap" ? aws_fsx_ontap_file_system.ontap-fs[0].id : null)
}

output "rwx_filestore_endpoint" {
  description = "The DNS name for the file system."
  value = (var.storage_type == "none"
    ? null
    : var.storage_type == "ha" && local.storage_type_backend == "efs" ? aws_efs_file_system.efs-fs[0].dns_name
    : var.storage_type == "ha" && local.storage_type_backend == "ontap" ? aws_fsx_ontap_storage_virtual_machine.ontap-svm[0].endpoints[0]["nfs"][0]["dns_name"] : module.nfs[0].private_dns
  )
}

output "rwx_filestore_path" {
  description = "OS path used for the file system."
  value = (var.storage_type == "none"
    ? null
    : local.storage_type_backend == "efs" ? "/"
    : local.storage_type_backend == "ontap" ? "/ontap" : "/export"
  )
}

output "efs_arn" {
  description = "Amazon Resource Name of the file system."
  value = var.storage_type == "ha" && local.storage_type_backend == "efs" ? aws_efs_file_system.efs-fs[0].arn : null
}

output "jump_private_ip" {
  description = "Private IP address associated with the Jump Server instance."
  value       = var.create_jump_vm ? module.jump[0].private_ip_address : null
}

output "jump_public_ip" {
  description = "Public IP address associated with the Jump Server instance."
  value       = var.create_jump_vm ? module.jump[0].public_ip_address : null
}

output "jump_admin_username" {
  description = "Admin username for the Jump Server instance."
  value       = var.create_jump_vm ? module.jump[0].admin_username : null
}

output "jump_private_dns" {
  description = "Private DNS name assigned to the Jump Server instance."
  value       = var.create_jump_vm ? module.jump[0].private_dns : null
}

output "jump_public_dns" {
  description = "Public DNS name assigned to the Jump Server instance."
  value       = var.create_jump_vm ? module.jump[0].public_dns : null
}

output "jump_rwx_filestore_path" {
  description = "OS path used in cloud-init for NFS integration."
  value = (var.storage_type != "none"
    ? var.create_jump_vm ? var.jump_rwx_filestore_path : null
    : null
  )
}

output "nfs_private_ip" {
  description = "Private IP address associated with the NFS Server instance."
  value       = var.storage_type == "standard" ? module.nfs[0].private_ip_address : null
}

output "nfs_public_ip" {
  description = "Public IP address associated with the NFS Server instance."
  value       = var.storage_type == "standard" ? module.nfs[0].public_ip_address : null
}

output "nfs_admin_username" {
  description = "Admin username for the NFS Server instance."
  value       = var.storage_type == "standard" ? module.nfs[0].admin_username : null
}

output "nfs_private_dns" {
  description = "Private DNS name assigned to the NFS Server instance."
  value       = var.storage_type == "standard" ? module.nfs[0].private_dns : null
}

output "nfs_public_dns" {
  description = "Public DNS name assigned to the NFS Server instance."
  value       = var.storage_type == "standard" ? module.nfs[0].public_dns : null
}

#postgres
output "postgres_servers" {
  description = "Map of PostgreSQL server objects."
  value       = length(module.postgresql) != 0 ? local.postgres_outputs : null
  sensitive   = true
}

output "nat_ip" {
  description = "List of public Elastic IPs created for AWS NAT Gateway."
  value = module.vpc.create_nat_gateway ? module.vpc.nat_public_ips[0] : null
}

output "prefix" {
  description = "The prefix used in the name for all cloud resources created by this script."
  value       = var.prefix
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = local.cluster_name
}

output "provider" {
  description = "Public cloud provider infrastructure components are deployed for."
  value       = "aws"
}

output "location" {
  description = "AWS Region where all resources in this script were provisioned."
  value       = var.location
}

## Reference for Amazon ECR private registries: https://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html
output "cr_endpoint" {
  description = "The default private registry URL."
  value       = "https://${data.aws_caller_identity.terraform.account_id}.dkr.ecr.${var.location}.amazonaws.com"
}

output "cluster_node_pool_mode" {
  description = "Cluster node configuration."
  value       = var.cluster_node_pool_mode
}

output "autoscaler_account" {
  description = "ARN of IAM role for cluster-autoscaler."
  value       = var.autoscaling_enabled ? module.autoscaling[0].autoscaler_account : null
}

output "cluster_api_mode" {
  description = "Use Public or Private IP address for the cluster API endpoint."
  value       = var.cluster_api_mode
}

output "ebs_csi_account" {
  description = "ARN of IAM role for ebs-csi-controller Service Account."
  value       = module.ebs.ebs_csi_account
}

output "k8s_version" {
  description = "Kubernetes master version."
  value       = module.eks.cluster_version
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
