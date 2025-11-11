# AWS Load Balancer Controller Terraform module

data "aws_caller_identity" "current" {}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "kube-system"
  set = [
    {
      name  = "installCRDs"
      value = "true"
    }
  ]
  depends_on = [var.kubeconfig_depends_on]
}

resource "helm_release" "aws_lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = var.controller_version
  namespace  = "kube-system"
  
  # Base configuration for all deployments
  set {
    name  = "clusterName"
    value = var.cluster_name
  }
  
  set {
    name  = "region"
    value = var.region
  }
  
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.lb_controller_role.arn
  }
  
  set {
    name  = "enableServiceMutatorWebhook"
    value = "false"
  }
  
  set {
    name  = "defaultSSLPolicy"
    value = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }
  
  set {
    name  = "defaultTargetType"
    value = "ip"
  }
  
  # IPv6-specific configuration
  dynamic "set" {
    for_each = var.enable_ipv6 ? [1] : []
    content {
      name  = "defaultAddressType"
      value = "ipv6"
    }
  }
  
  dynamic "set" {
    for_each = var.enable_ipv6 ? [1] : []
    content {
      name  = "enableIPv6"
      value = "true"
    }
  }
  
  depends_on = [helm_release.cert_manager]
}

resource "aws_iam_policy" "lb_controller_policy" {
  name        = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  path        = "/"
  description = "IAM policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "lb_controller_role" {
  name = "${var.cluster_name}-AWSLoadBalancerControllerRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.cluster_oidc_issuer_url, "https://", "")}" }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(var.cluster_oidc_issuer_url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lb_controller_attach" {
  role       = aws_iam_role.lb_controller_role.name
  policy_arn = aws_iam_policy.lb_controller_policy.arn
}
