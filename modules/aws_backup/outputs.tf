output "backup_vault_arn" {
  description = "The ARN of the created Backup Vault"
  value       = aws_backup_vault.spoke.arn
}

# output "backup_external" {
#   description = "Result of the shell script"
#   value       = var.backup_external == "true" ? var.existing_backup_arn : aws_backup_vault.spoke.arn
# }