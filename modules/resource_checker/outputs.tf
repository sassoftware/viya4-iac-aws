output "waf_external" {
  description = "Result of the shell script"
  value       = data.external.waf_checker_tool.result
}

output "bucket_external" {
  description = "Result of the shell script"
  value       = data.external.bucket_checker_tool.result
}


output "analyzer_external" {
  description = "Result of the shell script"
  value       = data.external.analyzer_checker_tool.result
}

output "backup_external" {
  description = "Result of the shell script"
  value       = data.external.vault_checker_tool.result
}

