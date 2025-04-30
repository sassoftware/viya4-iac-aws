# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "prefix" {
  description = "A prefix used for all AWS Cloud resources created by this script"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags used for fsx_ontap"
  type        = map(any)
  default     = null
}

variable "iam_user_name" {
  description = "AWS caller user name parsed from the ARN value"
  type        = string
  default     = ""
}

variable "is_user" {
  description = "Boolean value indicating if the caller identity is a user as opposed to a role"
  type        = bool
  default     = false
}

variable "iam_role_name" {
  description = "AWS caller role name parsed from the ARN value"
  type        = string
  default     = ""
}
