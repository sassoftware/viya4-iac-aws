# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "ebs_csi_account" {
  description = "ARN of IAM role for ebs-csi-controller Service Account. This IAM role is used by the EBS CSI controller to manage AWS resources on behalf of the Kubernetes cluster, such as creating and attaching EBS volumes."
  value       = module.iam_assumable_role_with_oidc.iam_role_arn
}
