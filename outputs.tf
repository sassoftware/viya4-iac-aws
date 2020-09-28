output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}

output "kube_config" {
  description = "kubectl config as generated by the module."
  value       = module.eks.kubeconfig
}

# output "aws_config_map_auth" {
#   description = "A kubernetes configuration to authenticate to this EKS cluster."
#   value       = module.eks.config_map_aws_auth
# }

output "worker_iam_role_arn" {
  value = module.eks.worker_iam_role_arn
}

output "rwx_filestore_id" {
  value = aws_efs_file_system.efs-fs.id
}

output "rwx_filestore_endpoint" {
  value = aws_efs_file_system.efs-fs.dns_name
}

output "rwx_filestore_path" {
  value = "/"
}

output "efs_arn" {
  value = aws_efs_file_system.efs-fs.arn
}

output "jump_private_ip" {
  value = var.create_jump_vm ? module.jump.private_ip_address : ""
}

output "jump_public_ip" {
  value = var.create_jump_vm ? module.jump.public_ip_address : ""
}

output "jump_private_dns" {
  value = var.create_jump_vm ? module.jump.private_dns : ""
}

output "jump_public_dns" {
  value = var.create_jump_vm ? module.jump.public_dns : ""
}

output "postgres_fqdn" {
  value = var.create_postgres ? module.db.this_db_instance_endpoint : ""
}

output "postgres_admin" {
  value = var.create_postgres ? module.db.this_db_instance_username : ""
}

output "postgres_password" {
  value = var.create_postgres ? module.db.this_db_instance_password : ""
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

output "location" {
  value = var.location
}