# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# The `kube_config` output provides the necessary credentials and endpoint information
# required to access the Kubernetes cluster using `kubectl`, the command-line tool for
# interacting with Kubernetes. This output is essential for configuring `kubectl` to
# communicate with the cluster's API server, enabling users to manage and deploy
# applications on the Kubernetes cluster.
output "kube_config" {
  description = "Kubernetes cluster authentication information for kubectl."
  value       = local_file.kubeconfig.content
}
