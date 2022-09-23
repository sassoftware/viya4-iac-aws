variable "prefix" {
  description = "A prefix used for all AWS Cloud resources created by this script"
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags used for aws ebs csi objects"
  default     = null
}

variable "oidc_url" {
  description = "OIDC URL of EKS cluster"
  type        = string
  default     = null
}
