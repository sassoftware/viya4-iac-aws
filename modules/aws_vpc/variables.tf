# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# List of availability zones for public subnets. Used to distribute public resources across multiple AZs for high availability.
variable "public_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the public subnets"
  type        = list(string)
  default     = []
}

# List of availability zones for private subnets. Used to distribute private resources across multiple AZs for high availability.
variable "private_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the private subnets"
  type        = list(string)
  default     = []
}

# List of availability zones for control plane subnets. Used for Kubernetes/EKS control plane components.
variable "control_plane_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the control plane subnets"
  type        = list(string)
  default     = []
}

# List of availability zones for database subnets. Used for RDS or other database resources.
variable "database_subnet_azs" {
  description = "A list of availability zones names or ids in the region for creating the database subnets"
  type        = list(string)
  default     = []
}

# Existing VPC ID to use instead of creating a new one. Useful for shared or pre-existing networks.
variable "vpc_id" {
  description = "Existing vpc id"
  type        = string
  default     = null
}

# Prefix for naming VPC resources. Used for resource identification and grouping.
variable "name" {
  description = "Prefix used when creating VPC resources"
  type        = string
  default     = null
}

# CIDR block for the VPC. Defines the IP address range for the network.
variable "cidr" {
  type        = string
  description = "The CIDR block for the VPC"
}

variable "enable_ipv6" {
  description = "Enable IPv6"
  type        = bool
  default     = false
}

# Map of subnet roles to lists of subnet CIDR blocks. Used for custom subnet layouts.
variable "subnets" {
  type        = map(any)
  description = "Map of list of subnet cidr_blocks"
}

# Map of subnet usage roles to existing subnet IDs. Allows using pre-existing subnets for specific purposes.
variable "existing_subnet_ids" {
  type        = map(list(string))
  default     = {}
  description = "Map subnet usage roles to existing list of subnet ids"
}

# Pre-existing NAT Gateway ID to use for outbound internet access from private subnets.
variable "existing_nat_id" {
  type        = string
  default     = null
  description = "Pre-existing VPC NAT Gateway id"
}

# If true, enables DNS hostnames in the VPC. Required for certain AWS services.
variable "enable_dns_hostnames" {
  description = "Should be true to enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

# If true, enables DNS support in the VPC. Required for name resolution within the VPC.
variable "enable_dns_support" {
  description = "Should be true to enable DNS support in the VPC"
  type        = bool
  default     = true
}

# Map of tags to apply to the VPC and subnets for cost allocation and management.
variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)
  default     = {}
}

# Additional tags for public subnets.
variable "public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

# Additional tags for private subnets.
variable "private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

# Suffix to append to public subnet names. Default is 'public'.
variable "public_subnet_suffix" {
  description = "Suffix to append to public subnets name"
  type        = string
  default     = "public"
}

# Suffix to append to private subnet names. Default is 'private'.
variable "private_subnet_suffix" {
  description = "Suffix to append to private subnets name"
  type        = string
  default     = "private"
}

# Suffix to append to database subnet names. Default is 'db'.
variable "database_subnet_suffix" {
  description = "Suffix to append to database subnets name"
  type        = string
  default     = "db"
}

# Suffix to append to control plane subnet names. Default is 'control-plane'.
variable "control_plane_subnet_suffix" {
  description = "Suffix to append to control plane subnets name"
  type        = string
  default     = "control-plane"
}

# If true, automatically assigns a public IP to instances launched in public subnets.
variable "map_public_ip_on_launch" {
  description = "Should be false if you do not want to auto-assign public IP on launch"
  type        = bool
  default     = true
}

# Map of VPC endpoints to create for private clusters. Key is the service name, value is the endpoint type.
variable "vpc_private_endpoints" {
  description = "Endpoints needed for private cluster"
  type        = map(string)
  default = {
    "ec2"                  = "Interface",
    "ecr.api"              = "Interface",
    "ecr.dkr"              = "Interface",
    "s3"                   = "Interface",
    "logs"                 = "Interface",
    "sts"                  = "Interface",
    "elasticloadbalancing" = "Interface",
    "autoscaling"          = "Interface"
  }
}

# If true, enables creation of VPC private endpoint resources for private networking.
variable "vpc_private_endpoints_enabled" {
  description = "Enable the creation of vpc private endpoint resources"
  type        = bool
  default     = true
}

# AWS region for the VPC and subnets.
variable "region" {
  description = "Region"
  type        = string
}

# Security group ID for the VPC or subnets. Used for network access control.
variable "security_group_id" {
  description = "Security Group ID local variable value"
  type        = string
}

# Raw security group ID input variable. Used for advanced or custom setups.
variable "raw_sec_group_id" {
  description = "Security Group ID input variable value"
  type        = string
}

# Security group ID for the Kubernetes/EKS cluster.
variable "cluster_security_group_id" {
  description = "Cluster Security Group ID input variable value"
  type        = string
}

# Security group ID for worker nodes in the Kubernetes/EKS cluster.
variable "workers_security_group_id" {
  description = "Workers Security Group ID input variable value"
  type        = string
}
