variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the EKS cluster."
  type        = string
}

variable "lb_controller_version" {
  description = "Version of AWS Load Balancer Controller."
  type        = string
  default     = "v2.11.0"
}

variable "cert_manager_version" {
  description = "Version of cert-manager."
  type        = string
  default     = "v1.17.0"
}
