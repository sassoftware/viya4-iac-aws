variable "prefix" {
  description = "Prefix for CloudWatch alarm names"
  type        = string
}

variable "cpu_threshold" {
  description = "Threshold for CPU utilization"
  type        = number
  default     = 80
}


variable "billing_threshold" {
  description = "Threshold for CPU utilization"
  type        = number
  default     = 2500
}


variable "enable_nist_features" {
  description = "A flag to enable NIST features under development for this project"
  type        = bool
  default     = false # set it to true for NIST enchancements
}

variable "storage_type_backend" {
  description = "The storage backend used for the chosen storage type. Defaults to 'nfs' for storage_type='standard'. Defaults to 'efs for storage_type='ha'. 'efs' and 'ontap' are valid choices for storage_type='ha'."
  type        = string
  default     = "nfs"
  # If storage_type is standard, this will be set to "nfs"

  validation {
    condition     = contains(["nfs", "efs", "ontap", "none"], lower(var.storage_type_backend))
    error_message = "ERROR: Supported values for `storage_type_backend` are nfs, efs, ontap and none."
  }
}

variable "efs_id" {
  description = "EFS is"
  type        = string
}

variable "fsx_id" {
  description = "FSx is"
  type        = string
}

variable "cloudwatch_monitor_severity" {
  type = map(number)
  default = {
    "threshold_active_flow"     = "100"
    "threshold_processed_bytes" = "4000000"
    "threshold_unhealthy_host"  = "1"
    "threshold_peak_packets"    = "1000"
    "cpu_threshold"             = "90"
    "ram_threshold"             = "90"
    "disk_utilization"          = "90"
    "ebs_read_threshold"        = "9000"
    "ebs_write_threshold"       = "9000"
    "billing_threshold"         = "6000"
    "ec2statuscheck"            = "1"
  }
}

variable "cloudwatch_monitor_thresholds" {
  type = map(string)
  default = {
    "threshold_active_flow"     = "Severity3"
    "threshold_processed_bytes" = "Severity3"
    "threshold_unhealthy_host"  = "Severity2"
    "threshold_peak_packets"    = "Severity3"
    "cpu_threshold"             = "Severity2"
    "ram_threshold"             = "Severity2"
    "disk_utilization"          = "Severity2"
    "ebs_read_threshold"        = "Severity2"
    "ebs_write_threshold"       = "Severity2"
    "billing_threshold"         = "Severity2"
    "ec2statuscheck"            = "Severity2"
  }
}

variable "tags" {
  description = "The tags to associate with resources when enable_nist_features is set to true."
  type        = map(string)
  default     = {}
}

variable "hub_environment" {
  description = "name of the hub_environment"
  type        = string
}

variable "location" {
  description = "Region of deployment"
  type        = string
}

variable "spoke_account_id" {
  description = "spoke account id for s3 deployment"
  type        = string
}

