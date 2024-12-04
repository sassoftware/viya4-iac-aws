################################################################################
#                          VPC FLOW LOGS TO S3                                 #
################################################################################

variable "local_s3_bucket_arn" {
  description = "Local Spoke S3 Bucket ARN"
  type        = string
}

variable "location" {
  type        = string
  description = "Region of deployment"
}

variable "spoke_account_id" {
  description = "spoke account id for s3 deployment"
  type        = string
}

# variable "waf_external" {
#   type        = string
#   default     = "true"
#   description = "Type of the resource"
# }

# variable "existing_waf_arn" {
#   description = "existing arn values"
#   type = string
# }

variable "tags" {
  description = "Map of common tags to be placed on the Resources only if NIST is set to true"
  type        = map(any)
}
