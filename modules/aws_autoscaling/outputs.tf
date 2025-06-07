# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "autoscaler_account" {
  description = "ARN of IAM role for cluster-autoscaler. This role is assumed by the cluster-autoscaler service to manage the scaling of the cluster's node groups. It is crucial for enabling the autoscaler to interact with other AWS services on behalf of the user."
  value       = module.iam_assumable_role_with_oidc.iam_role_arn
}
