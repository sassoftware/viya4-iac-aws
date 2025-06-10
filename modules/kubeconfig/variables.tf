# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Prefix for all Google Cloud resources created by this module. Used for resource naming and identification.
variable "prefix" {
  description = "A prefix used for all Google Cloud resources created by this script"
  type        = string
}

# Kubernetes namespace for the service account and cluster role binding. Default is 'kube-system'.
variable "namespace" {
  description = "Namespace that the service account and cluster role binding will placed."
  type        = string
  default     = "kube-system"
}

# AWS region where the cluster was provisioned. Used for context in multi-region deployments.
variable "region" {
  description = "AWS Region this cluster was provisioned in"
  type        = string
  default     = null
}

# If true, creates a kubeconfig file using a provider/service account. Useful for automation and CI/CD.
variable "create_static_kubeconfig" {
  description = "Allows the user to create a provider / service account based kube config file"
  type        = bool
  default     = false
}

# Path where the generated kubeconfig file will be saved.
variable "path" {
  description = "Path to output the kubeconfig file"
  type        = string
}

# Name of the Kubernetes cluster for which the kubeconfig is generated.
variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

# Endpoint URL of the Kubernetes cluster API server.
variable "endpoint" {
  description = "Kubernetes cluster endpoint"
  type        = string
}

# Base64-encoded CA certificate for the Kubernetes cluster. Used for secure API access.
variable "ca_crt" {
  description = "Kubernetes CA certificate"
  type        = string
}

# Security group ID associated with the cluster or resources.
variable "sg_id" {
  description = "Security group ID"
  type        = string
}
