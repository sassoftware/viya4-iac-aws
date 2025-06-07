# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Prefix for all AWS resources created by this module. Ensures resource names are unique and easily identifiable.
variable "prefix" {
  description = "A prefix used for all AWS Cloud resources created by this script"
  type        = string
  default     = ""
}

# Name of the EKS cluster for which autoscaling is being configured.
variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = ""
}

# Map of tags to apply to all autoscaling resources for cost allocation and management.
variable "tags" {
  description = "Tags used for autoscaling"
  type        = map(any)
  default     = null
}

# OIDC (OpenID Connect) URL for the EKS cluster, used for IAM roles for service accounts.
variable "oidc_url" {
  description = "OIDC URL of EKS cluster"
  type        = string
  default     = ""
}
