# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


locals {
  # Constructed names for service account, cluster role binding, and service account secret
  service_account_name        = "${var.prefix}-cluster-admin-sa"
  cluster_role_binding_name   = "${var.prefix}-cluster-admin-crb"
  service_account_secret_name = "${var.prefix}-sa-secret"

  # Provider based kube config data/template/resources
  kubeconfig_provider = var.create_static_kubeconfig ? null : templatefile("${path.module}/templates/kubeconfig-provider.tmpl", {
    cluster_name = var.cluster_name
    endpoint     = var.endpoint
    ca_crt       = var.ca_crt
    region       = var.region
    }
  )

  # Service Account based kube config data/template/resources
  kubeconfig_sa = var.create_static_kubeconfig ? templatefile("${path.module}/templates/kubeconfig-sa.tmpl", {
    cluster_name = var.cluster_name
    endpoint     = var.endpoint
    name         = local.service_account_name
    ca_crt       = base64encode(lookup(data.kubernetes_secret.sa_secret[0].data, "ca.crt", ""))
    token        = lookup(data.kubernetes_secret.sa_secret[0].data, "token", "")
    namespace    = var.namespace
    }
  ) : null

}

data "aws_security_group" "selected" {
  id = var.sg_id
}

data "kubernetes_secret" "sa_secret" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = kubernetes_secret.sa_secret[0].metadata[0].name
    namespace = var.namespace
  }
  depends_on = [kubernetes_secret.sa_secret]
}

# 1.24 change: Create service account secret
resource "kubernetes_secret" "sa_secret" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.service_account_secret_name
    namespace = var.namespace
    annotations = {
      "kubernetes.io/service-account.name" = local.service_account_name
    }
  }
  type = "kubernetes.io/service-account-token"

  depends_on = [
    kubernetes_service_account.kubernetes_sa,
    data.aws_security_group.selected,
  ]
}

# Starting K8s v1.24+ hashicorp/terraform-provider-kubernetes issues warning message:
# "Warning: 'default_secret_name' is no longer applicable for Kubernetes 'v1.24.0' and above"
resource "kubernetes_service_account" "kubernetes_sa" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = local.service_account_name
    namespace = var.namespace
  }
}

resource "kubernetes_cluster_role_binding" "kubernetes_crb" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name = local.cluster_role_binding_name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account_name
    namespace = var.namespace
  }

  depends_on = [
    data.aws_security_group.selected,
    local_file.kubeconfig
  ]
}

# kube config file generation
resource "local_file" "kubeconfig" {
  content              = var.create_static_kubeconfig ? local.kubeconfig_sa : local.kubeconfig_provider
  filename             = var.path
  file_permission      = "0644"
  directory_permission = "0755"
}
