# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "autoscaler_account" {
  description = "ARN of IAM role for cluster-autoscaler."
  value       = module.iam_assumable_role_with_oidc.iam_role_arn
}
