# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# tflint-ignore: terraform_standard_module_structure
output "kube_config" {
  value = local_file.kubeconfig.content
}
