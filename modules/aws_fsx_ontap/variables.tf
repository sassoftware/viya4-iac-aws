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

variable "iam_name" {
  description = "AWS caller identity name parsed from the ARN value"
  type        = string
  default     = ""
}

variable "is_user" {
  description = "Boolean value to determine if the caller identity is a user"
  type        = bool
  default     = false
}
