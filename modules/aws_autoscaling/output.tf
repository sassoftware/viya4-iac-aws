# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "autoscaler_account" {
  value = module.iam_assumable_role_with_oidc.iam_role_arn
}
