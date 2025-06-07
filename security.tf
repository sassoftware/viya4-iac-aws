# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Data source to fetch the existing security group details if security_group_id is provided
data "aws_security_group" "sg" {
  count = var.security_group_id == null ? 0 : 1
  id    = var.security_group_id
}

# Note:
# Using aws_vpc_security_group_egress_rule and aws_vpc_security_group_ingress_rule resources is the current best practice. 
# Avoid using the aws_security_group_rule resource and the ingress and egress arguments of the aws_security_group resource 
# for configuring in-line rules, as they struggle with managing multiple CIDR blocks, and tags and descriptions due to the 
# historical lack of unique IDs.

# Security Groups - https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "sg" {
  count  = var.security_group_id == null ? 1 : 0
  name   = "${var.prefix}-sg"
  vpc_id = module.vpc.vpc_id

  description = "Auxiliary security group associated with RDS ENIs and VPC Endpoint ENIs as well as Jump/NFS VM ENIs when they have public IPs"

  tags = merge(local.tags, { "Name" : "${var.prefix}-sg" })
}

# Egress rule to allow all outbound traffic from the security group
resource "aws_vpc_security_group_egress_rule" "sg" {

  security_group_id = local.security_group_id

  description = "Allow all outbound traffic."
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(local.tags, { "Name" : "${var.prefix}-sg" })
}

# Only create this/these ingress rule(s) if we are using VPC Endpoints
# Creates an ingress rules for each vpc_endpoint_private_access_cidrs in the list
resource "aws_vpc_security_group_ingress_rule" "sg" {

  for_each = var.security_group_id == null && var.vpc_private_endpoints_enabled ? toset(local.vpc_endpoint_private_access_cidrs) : toset([])

  security_group_id = local.security_group_id
  description       = "Allow tcp port 443 ingress to all AWS Services targeted by the VPC endpoints"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = each.key

  tags = merge(local.tags, { "Name" : "${var.prefix}-sg" })
}

# Ingress rule to allow SSH access to VMs from specified CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "vms" {

  for_each = var.security_group_id == null && ((var.create_jump_public_ip && var.create_jump_vm) || (var.create_nfs_public_ip && var.storage_type == "standard")) ? toset(local.vm_public_access_cidrs) : toset([])

  security_group_id = local.security_group_id

  description = "Allow SSH from source"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

# Ingress rule to allow internal communication within the same security group
resource "aws_vpc_security_group_ingress_rule" "all" {
  security_group_id = local.security_group_id

  description                  = "Allow internal security group communication."
  ip_protocol                  = "-1"
  referenced_security_group_id = local.security_group_id
}

# Ingress rule to allow PostgreSQL traffic within the network
resource "aws_vpc_security_group_ingress_rule" "postgres_internal" {

  for_each = local.postgres_sgr_ports != null ? toset(local.postgres_sgr_ports) : toset([])

  description                  = "Allow Postgress within network"
  from_port                    = each.key
  to_port                      = each.key
  ip_protocol                  = "tcp"
  security_group_id            = local.security_group_id
  referenced_security_group_id = local.security_group_id
}

# Ingress rule to allow PostgreSQL traffic from specified external CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "postgres_external" {

  for_each = (length(local.postgres_public_access_cidrs) > 0
    ? local.postgres_sgr_ports != null
    ? local.ingress_pairs
    : {}
    : {}
  )

  description       = "Allow Postgres from source"
  from_port         = each.value.server_port
  to_port           = each.value.server_port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value.cidr
  security_group_id = local.security_group_id
}

# Security group for the EKS cluster
resource "aws_security_group" "cluster_security_group" {

  count = var.cluster_security_group_id == null ? 1 : 0

  name        = "${var.prefix}-eks_cluster_sg"
  vpc_id      = module.vpc.vpc_id
  description = "EKS cluster security group."

  tags = merge(local.tags, { "Name" : "${var.prefix}-eks_cluster_sg" })

}

# Egress rule to allow all outbound traffic from the EKS cluster security group
resource "aws_vpc_security_group_egress_rule" "cluster_security_group" {

  count = var.cluster_security_group_id == null ? 1 : 0

  description       = "Allow all outbound traffic."
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = local.cluster_security_group_id
}

# Ingress rule to allow HTTPS access to the EKS cluster API server from specified CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "cluster_security_group" {

  for_each = var.cluster_security_group_id == null ? toset(local.cluster_endpoint_private_access_cidrs) : toset([])

  description       = "Allow additional HTTPS/443 ingress to private EKS cluster API server endpoint per var.cluster_endpoint_private_access_cidrs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
  security_group_id = local.cluster_security_group_id
}


# Ingress rule to allow communication between EKS pods and the cluster API
resource "aws_vpc_security_group_ingress_rule" "cluster_ingress" {

  count = var.cluster_security_group_id == null ? 1 : 0

  description                  = "Allow pods to communicate with the EKS cluster API."
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.workers_security_group_id
  security_group_id            = local.cluster_security_group_id
}

# Security group for the EKS worker nodes
resource "aws_security_group" "workers_security_group" {

  count = var.workers_security_group_id == null ? 1 : 0

  description = "Security group for all nodes in the cluster."
  name        = "${var.prefix}-eks_worker_sg"
  vpc_id      = module.vpc.vpc_id
  tags = merge(local.tags,
    { "Name" : "${var.prefix}-eks_worker_sg" },
    { "kubernetes.io/cluster/${local.cluster_name}" : "owned" }
  )
}

# Egress rule to allow all outbound traffic from the EKS worker nodes security group
resource "aws_vpc_security_group_egress_rule" "workers_security_group" {

  count = var.workers_security_group_id == null ? 1 : 0

  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = local.workers_security_group_id
  description       = "Allow cluster egress access to the Internet."
  ip_protocol       = "-1"

}

# Ingress rule to allow communication between EKS worker nodes
resource "aws_vpc_security_group_ingress_rule" "worker_self" {

  count = var.workers_security_group_id == null ? 1 : 0

  description                  = "Allow node to communicate with each other."
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.workers_security_group[0].id
  security_group_id            = aws_security_group.workers_security_group[0].id
}

# Ingress rule to allow communication from the cluster control plane to worker pods
resource "aws_vpc_security_group_ingress_rule" "worker_cluster_api" {

  count = var.workers_security_group_id == null ? 1 : 0

  description                  = "Allow worker pods to receive communication from the cluster control plane."
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.cluster_security_group_id
  security_group_id            = aws_security_group.workers_security_group[0].id
}

# Ingress rule to allow communication from the cluster control plane to worker pods on port 443
resource "aws_vpc_security_group_ingress_rule" "worker_cluster_api_443" {

  count = var.workers_security_group_id == null ? 1 : 0

  description                  = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane."
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.cluster_security_group_id
  security_group_id            = aws_security_group.workers_security_group[0].id
}

# TODO: Make sure tags are applied to all resources

# Ingress rule to allow SSH access to a private IP based Jump VM from specified CIDR blocks
resource "aws_vpc_security_group_ingress_rule" "vm_private_access_22" {

  for_each = (length(local.vm_private_access_cidrs) > 0
    && var.workers_security_group_id == null
    && ((var.create_jump_public_ip == false && var.create_jump_vm)
    || (var.create_nfs_public_ip == false && var.storage_type == "standard")) ? toset(local.vm_private_access_cidrs) : toset([])
  )

  description       = "Allow SSH to a private IP based Jump VM per var.vm_private_access_cidrs. Required for DAC baseline client VM."
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
  security_group_id = aws_security_group.workers_security_group[0].id
}
