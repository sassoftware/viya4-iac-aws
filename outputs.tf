output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kube_config" {
  value     = module.kubeconfig.kube_config
  sensitive = true
}

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}
output "cluster_iam_role_arn" {
  value = module.eks.cluster_iam_role_arn
}

output "rwx_filestore_id" {
  value = var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.id : null
}

output "rwx_filestore_endpoint" {
  value = ( var.storage_type == "none"
            ? null
            : var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.dns_name : module.nfs.0.private_dns
          )
}

output "rwx_filestore_path" {
  value = ( var.storage_type == "none"
            ? null
            : var.storage_type == "ha" ? "/" : "/export"
          )
}

output "efs_arn" {
  value = var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.arn : null
}

output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump.0.private_ip_address : null
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump.0.public_ip_address : null
}

output jump_admin_username {
  value = var.create_jump_vm ? module.jump.0.admin_username : null
}

output "jump_private_dns" {
  value = var.create_jump_vm ? module.jump.0.private_dns : null
}

output "jump_public_dns" {
  value = var.create_jump_vm ? module.jump.0.public_dns : null
}

output jump_rwx_filestore_path {
  value = ( var.storage_type != "none"
            ? var.create_jump_vm ? var.jump_rwx_filestore_path : null 
            : null 
          )
}

output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs.0.private_ip_address : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" ? module.nfs.0.public_ip_address : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs.0.admin_username : null
}

output "nsf_private_dns" {
  value = var.storage_type == "standard" ? module.nfs.0.private_dns : null
}

output "nfs_public_dns" {
  value = var.storage_type == "standard" ? module.nfs.0.public_dns : null
}

#postgres
output "postgres_servers" {
  value = length(module.postgresql) != 0 ? local.postgres_outputs : null
  sensitive = true
}

output "nat_ip" {
  value = module.vpc.nat_public_ips[0]
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
  value = var.autoscaling_enabled ? module.autoscaling.0.autoscaler_account : null
}

output "infra_mode" {
  value = var.infra_mode
}
