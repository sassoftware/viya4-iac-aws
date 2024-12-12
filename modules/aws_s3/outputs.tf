
output "local_s3_bucket_arn" {
  description = "ARN of the bucket"
  value       = var.bucket_external == "true" ? "aws-waf-logs-infra-${var.spoke_account_id}-${var.location}-bkt" : aws_s3_bucket.local_s3_bucket.arn
}

output "bucket_name" {
  description = "S3 name"
  value       = var.bucket_external == "true" ? "aws-waf-logs-infra-${var.spoke_account_id}-${var.location}-bkt" : aws_s3_bucket.local_s3_bucket.id
}


