variable "prefix" {
  description = "Prefix for CloudWatch alarm names"
  type        = string
}

variable "cpu_threshold" {
  description = "Threshold for CPU utilization"
  type        = number
  default     = 80
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

