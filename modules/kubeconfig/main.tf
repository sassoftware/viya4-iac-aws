locals {
  service_account_name        = "${var.prefix}-cluster-admin-sa"
  cluster_role_binding_name   = "${var.prefix}-cluster-admin-crb"
  service_account_secret_name = "${var.prefix}-sa-secret"
}

# Service Account based kube config data/template/resources
data "kubernetes_secret" "sa_secret" {
  count = var.create_static_kubeconfig ? 1 : 0
  metadata {
    name      = kubernetes_service_account.kubernetes_sa.0.default_secret_name
    namespace = var.namespace
  }
}


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
    name      = local.cluster_role_binding_name
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
}

# kube config file generation
resource "local_file" "kubeconfig" {
  content              = (var.create_static_kubeconfig
    ? templatefile(
        "${path.module}/templates/kubeconfig-sa.tmpl",
        {
          cluster_name = var.cluster_name
          endpoint     = var.endpoint
          name         = local.service_account_name
          ca_crt       = base64encode(lookup(data.kubernetes_secret.sa_secret.0.data,"ca.crt", ""))
          token        = lookup(data.kubernetes_secret.sa_secret.0.data,"token", "")
          namespace    = var.namespace
        }
      )
    : templatefile(
        "${path.module}/templates/kubeconfig-provider.tmpl",
        {
          cluster_name = var.cluster_name
          endpoint     = var.endpoint
          ca_crt       = var.ca_crt
          region       = var.region
        }
      )
  )
  filename             = var.path
  file_permission      = "0644"
  directory_permission = "0755"
}
