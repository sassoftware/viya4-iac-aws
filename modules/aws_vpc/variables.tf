# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

variable "public_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the private subnets"
  type        = list(string)
  default     = []
}

variable "control_plane_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the control plane subnets"
  type        = list(string)
  default     = []
}

variable "database_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the database subnets"
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "Existing vpc id"
  type        = string
  default     = null
}

variable "name" {
  description = "Prefix used when creating VPC resources"
  type        = string
  default     = null
}

variable "cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "subnets" {
  type        = map(any)
  description = "Map of list of subnet cidr_blocks"
}

variable "existing_subnet_ids" {
  type        = map(list(string))
  default     = {}
  description = "Map subnet usage roles to existing list of subnet ids"
}

variable "existing_nat_id" {
  type        = string
  default     = null
  description = "Pre-existing VPC NAT Gateway id"
}

variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

variable "database_subnet_suffix" {
  description = "Suffix to append to database subnets name"
  type        = string
  default     = "db"
}

variable "control_plane_subnet_suffix" {
  description = "Suffix to append to control plane subnets name"
  type        = string
  default     = "control-plane"
}

variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  type        = bool
  default     = true
}

variable "vpc_private_endpoints" {
  description = "Endpoints needed for private cluster"
  type        = map(string)
  default = {
    "ec2"                  = "Interface",
    "ecr.api"              = "Interface",
    "ecr.dkr"              = "Interface",
    "s3"                   = "Gateway",
    "logs"                 = "Interface",
    "sts"                  = "Interface",
    "elasticloadbalancing" = "Interface",
    "autoscaling"          = "Interface"
  }
}

variable "vpc_private_endpoints_enabled" {
  description = "Enable the creation of vpc private endpoint resources"
  type        = bool
  default     = true
}

variable "region" {
  description = "Region"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID local variable value"
  type        = string
}

variable "raw_sec_group_id" {
  description = "Security Group ID input variable value"
  type        = string
}

variable "cluster_security_group_id" {
  description = "Cluster Security Group ID input variable value"
  type        = string
}

variable "workers_security_group_id" {
  description = "Workers Security Group ID input variable value"
  type        = string
}
