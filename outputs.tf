output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kube_config" {
  value = module.kubeconfig.kube_config
}

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "rwx_filestore_id" {
  value = var.storage_type == "ha" ? element(coalescelist(aws_efs_file_system.efs-fs.*.id, [""]), 0) : null
}

output "rwx_filestore_endpoint" {
  value = var.storage_type == "ha" ? element(coalescelist(aws_efs_file_system.efs-fs.*.dns_name, [""]), 0) : module.nfs.private_dns
}

output "rwx_filestore_path" {
  value = var.storage_type == "ha" ? "/" : "/export"
}

output "efs_arn" {
  value = var.storage_type == "ha" ? element(coalescelist(aws_efs_file_system.efs-fs.*.arn, [""]), 0) : null
}

output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump.private_ip_address : ""
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump.public_ip_address : ""
}

output jump_admin_username {
  value = var.create_jump_vm ? module.jump.admin_username : ""
}

output "jump_private_dns" {
  value = var.create_jump_vm ? module.jump.private_dns : ""
}

output "jump_public_dns" {
  value = var.create_jump_vm ? module.jump.public_dns : ""
}

output jump_rwx_filestore_path {
  value = var.create_jump_vm ? var.jump_rwx_filestore_path : null
}

output "nfs_private_ip" {
  value = var.storage_type == "standard" ? module.nfs.private_ip_address : null
}

output "nfs_public_ip" {
  value = var.storage_type == "standard" ? module.nfs.public_ip_address : null
}

output "nfs_admin_username" {
  value = var.storage_type == "standard" ? module.nfs.admin_username : null
}

output "nsf_private_dns" {
  value = var.storage_type == "standard" ? module.nfs.private_dns : null
}

output "nfs_public_dns" {
  value = var.storage_type == "standard" ? module.nfs.public_dns : null
}

output "postgres_fqdn" {
  value = var.create_postgres ? module.db.db_instance_address : ""
}

output "postgres_admin" {
  value = var.create_postgres ? module.db.db_instance_username : ""
  sensitive = true
}

output "postgres_password" {
  value = var.create_postgres ? module.db.db_instance_password : ""
  sensitive = true
}

output "postgres_server_name" {
  value = var.create_postgres ? module.db.db_instance_id : ""
}

output "postgres_server_port" {
  value = var.create_postgres ? module.db.db_instance_port : ""
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
