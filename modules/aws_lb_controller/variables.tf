variable "kubeconfig_depends_on" {
  description = "Resource to depend on for kubeconfig readiness (e.g., module.kubeconfig.kube_config)"
  type        = any
}
variable "controller_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
}

variable "cert_manager_version" {
  description = "Cert Manager Helm chart version"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "cluster_oidc_issuer_url" {
  description = "The OIDC issuer URL for the EKS cluster"
  type        = string
}

variable "enable_ipv6" {
  description = "Enable IPv6 configuration for AWS Load Balancer Controller"
  type        = bool
  default     = false
}
