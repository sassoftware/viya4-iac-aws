output "rds_monitoring_role" {
  description = "Role ARN of the RDS"
  value       = var.enable_nist_features == true ? aws_iam_role.rds_enhanced_monitoring[0].arn : null
}