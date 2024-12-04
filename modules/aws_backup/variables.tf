variable "backup_account_id" {
  type        = string
  description = "Central backup account"
}

variable "central_backup_operator" {
  description = "Backup operator role arn"
  type        = string
}

variable "central_restore_operator" {
  description = "Restore operator arn"
  type        = string
}

variable "central_backup_vault_us" {
  description = "Backup vault name"
  type        = string
}

variable "central_backup_vault_eu" {
  description = "Backup vault name"
  type        = string
}

variable "location" {
  description = "location"
  type        = string
}

# variable "environment" {
#   description = "Environment"
#   type        = string
# }

variable "org_id" {
  description = "AWS organization id"
  type        = string
}

variable "tags" {
  description = "The tags to associate with resources when enable_nist_features is set to true."
  type        = map(string)
  default     = {}
}


variable "spoke_backup_rules" {
  description = "AWS Spoke Backup Rules data structure"
  type = list(object({
    name                     = string
    schedule                 = optional(string)
    enable_continuous_backup = optional(bool)
    start_window             = optional(number)
    completion_window        = optional(number)
    recovery_point_tags      = optional(map(string))
    lifecycle = optional(object({
      cold_storage_after                        = optional(number)
      delete_after                              = optional(number)
      opt_in_to_archive_for_supported_resources = optional(bool)
    }))
    copy_action = optional(object({
      destination_vault_arn = optional(string)
      lifecycle = optional(object({
        cold_storage_after                        = optional(number)
        delete_after                              = optional(number)
        opt_in_to_archive_for_supported_resources = optional(bool)
      }))
    }))
  }))


}

variable "advanced_backup_setting" {
  description = "AWS backup options"
  type = object({
    backup_options = string
    resource_type  = string
  })
  default = null
}



# variable "backup_external" {
#   type        = string
#   default     = "true"
#   description = "Result from resource checker module"
# }

variable "spoke_account_id" {
  description = "spoke account id for s3 deployment"
  type        = string
}

# variable "existing_backup_arn" {
#   description = "local arn"
#   type        = string
# }

variable "hub_environment" {
  description = "name of the hub_environment"
  type        = string
}

