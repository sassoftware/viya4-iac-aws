/*output "config_rules" {
  value = aws_config_config_rule.config_rules
}*/

# output "nist_bucket_arn" {
#   description = "ARN of the bucket"
#   value       = var.config_external == "true" ? "arn:aws:s3:::sas-awsng-${var.spoke_account_id}-${var.location}-nist-bkt" : aws_s3_bucket.NIST_conformance_pack_bkt.arn
# }