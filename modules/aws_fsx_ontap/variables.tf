# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Prefix for all AWS resources created by this module. Ensures resource names are unique and easily identifiable.
variable "prefix" {
  description = "A prefix used for all AWS Cloud resources created by this script"
  type        = string
  default     = ""
}

# Map of tags to apply to all FSx ONTAP resources for cost allocation and management.
variable "tags" {
  description = "Tags used for fsx_ontap"
  type        = map(any)
  default     = null
}

# AWS IAM user name parsed from the ARN, used for resource ownership and permissions.
variable "iam_user_name" {
  description = "AWS caller user name parsed from the ARN value"
  type        = string
  default     = ""
}

# Boolean indicating if the caller identity is a user (true) or a role (false).
variable "is_user" {
  description = "Boolean value indicating if the caller identity is a user as opposed to a role"
  type        = bool
  default     = false
}

# AWS IAM role name parsed from the ARN, used for resource ownership and permissions.
variable "iam_role_name" {
  description = "AWS caller role name parsed from the ARN value"
  type        = string
  default     = ""
}
