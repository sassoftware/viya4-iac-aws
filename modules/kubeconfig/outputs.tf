# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "kube_config" {
  description = "Kubernetes cluster authentication information for kubectl."
  value       = local_file.kubeconfig.content
}
