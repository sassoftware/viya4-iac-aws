# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
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
  count = var.security_group_id == null && var.vpc_private_endpoints_enabled ? 1 : 0
  security_group_id = local.security_group_id

  description = "Allow all outbound traffic."
  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = merge(local.tags, { "Name" : "${var.prefix}-sg" })
}

# IPv6 egress rule to allow outbound traffic within VPC for IPv6 pods
resource "aws_vpc_security_group_egress_rule" "sg_ipv6" {
  count = var.enable_ipv6 ? 1 : 0

  security_group_id = local.security_group_id

  description = "Allow IPv6 outbound traffic within VPC."
  ip_protocol = "-1"
  cidr_ipv6   = module.vpc.vpc_ipv6_cidr

  tags = merge(local.tags, { "Name" : "${var.prefix}-sg-ipv6" })
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

resource "aws_vpc_security_group_ingress_rule" "vms" {

  for_each = var.security_group_id == null && ((var.create_jump_public_ip && var.create_jump_vm)) ? toset(local.vm_public_access_cidrs) : toset([])

  security_group_id = local.security_group_id

  description = "Allow SSH from source"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = each.key
}

# IPv6 ingress rule to allow SSH access to VMs from IPv6 within VPC
resource "aws_vpc_security_group_ingress_rule" "vms_ipv6" {
  count = var.enable_ipv6 && var.security_group_id == null && ((var.create_jump_public_ip && var.create_jump_vm) || (var.create_nfs_public_ip && var.storage_type == "standard")) ? 1 : 0

  security_group_id = local.security_group_id

  description = "Allow SSH from IPv6 within VPC"
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv6   = module.vpc.vpc_ipv6_cidr
}

# Ingress rule to allow internal communication within the same security group
resource "aws_vpc_security_group_ingress_rule" "all" {
  security_group_id = local.security_group_id

  description                  = "Allow internal security group communication."
  ip_protocol                  = "-1"
  referenced_security_group_id = local.security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "postgres_internal" {

  for_each = local.postgres_sgr_ports != null ? toset(local.postgres_sgr_ports) : toset([])

  description                  = "Allow Postgress within network"
  from_port                    = each.key
  to_port                      = each.key
  ip_protocol                  = "tcp"
  security_group_id            = local.security_group_id
  referenced_security_group_id = local.security_group_id
}

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

# IPv6 egress rule for EKS cluster to allow outbound traffic within VPC
resource "aws_vpc_security_group_egress_rule" "cluster_security_group_ipv6" {
  count = var.cluster_security_group_id == null && var.enable_ipv6 ? 1 : 0

  description       = "Allow IPv6 outbound traffic within VPC."
  ip_protocol       = "-1"
  cidr_ipv6         = module.vpc.vpc_ipv6_cidr
  security_group_id = local.cluster_security_group_id
}

resource "aws_vpc_security_group_ingress_rule" "cluster_security_group" {

  for_each = var.cluster_security_group_id == null ? toset(local.cluster_endpoint_private_access_cidrs) : toset([])

  description       = "Allow additional HTTPS/443 ingress to private EKS cluster API server endpoint per var.cluster_endpoint_private_access_cidrs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = each.key
  security_group_id = local.cluster_security_group_id
}


resource "aws_vpc_security_group_ingress_rule" "cluster_ingress" {

  count = var.cluster_security_group_id == null ? 1 : 0

  description                  = "Allow pods to communicate with the EKS cluster API."
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = local.workers_security_group_id
  security_group_id            = local.cluster_security_group_id
}

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

# IPv6 egress rule for EKS worker nodes to allow outbound traffic within VPC
resource "aws_vpc_security_group_egress_rule" "workers_security_group_ipv6" {
  count = var.workers_security_group_id == null && var.enable_ipv6 ? 1 : 0

  cidr_ipv6         = module.vpc.vpc_ipv6_cidr
  security_group_id = local.workers_security_group_id
  description       = "Allow IPv6 cluster egress access within VPC."
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

# IPv6 ingress rule to allow SSH access to a private IPv6 based Jump VM within VPC
resource "aws_vpc_security_group_ingress_rule" "vm_private_access_22_ipv6" {
  count = var.enable_ipv6 && var.workers_security_group_id == null && ((var.create_jump_public_ip == false && var.create_jump_vm) || (var.create_nfs_public_ip == false && var.storage_type == "standard")) ? 1 : 0

  description       = "Allow SSH to IPv6 Jump VM within VPC. Required for IPv6 DAC baseline client VM."
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv6         = module.vpc.vpc_ipv6_cidr
  security_group_id = aws_security_group.workers_security_group[0].id
}

################################################################################
# Network Load Balancer (NLB) Security Group
################################################################################
resource "aws_security_group" "nlb_security_group" {
  count       = var.enable_ipv6 ? 1 : 0
  name        = "${var.prefix}-eks_nlb_sg"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for AWS Network Load Balancers (NLB) with IPv6 support. Allows external traffic to reach ingress controllers."
 
  tags = merge(local.tags, { "Name" : "${var.prefix}-eks_nlb_sg" })
}
 
################################################################################
# Egress rules: NLB → worker nodes
################################################################################
# Egress rule to allow NLB to forward traffic to worker nodes (IPv4)
resource "aws_vpc_security_group_egress_rule" "nlb_to_workers_ipv4" {
  count = var.enable_ipv6 ? 1 : 0
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow NLB to forward traffic to worker nodes on all ports"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
 
# Egress rule to allow NLB to forward traffic to worker nodes (IPv6)
resource "aws_vpc_security_group_egress_rule" "nlb_to_workers_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow NLB to forward IPv6 traffic to worker nodes on all ports"
  ip_protocol       = "-1"
  cidr_ipv6         = "::/0"
}
 
################################################################################
# Ingress rules: Internet → NLB (HTTP/HTTPS)
################################################################################
resource "aws_vpc_security_group_ingress_rule" "nlb_http" {
  for_each = toset(var.default_public_access_cidrs)
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow HTTP traffic to NLB from custom CIDRs"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
 
  cidr_ipv4 = can(regex(":", each.key)) ? null : each.key
  cidr_ipv6 = can(regex(":", each.key)) ? each.key : null
}
 
resource "aws_vpc_security_group_ingress_rule" "nlb_https" {
  for_each = toset(var.default_public_access_cidrs)
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow HTTPS traffic to NLB from custom CIDRs"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
 
  cidr_ipv4 = can(regex(":", each.key)) ? null : each.key
  cidr_ipv6 = can(regex(":", each.key)) ? each.key : null
}
 
# Ingress rule to allow IPv6 HTTP traffic from the internet to NLB
# CRITICAL: Required for IPv6 NLB functionality
resource "aws_vpc_security_group_ingress_rule" "nlb_http_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow public IPv6 HTTP traffic to NLB. Required for IPv6 client access."
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
}
 
# Ingress rule to allow IPv6 HTTPS traffic from the internet to NLB
# CRITICAL: Required for IPv6 NLB functionality
resource "aws_vpc_security_group_ingress_rule" "nlb_https_ipv6" {
  count = var.enable_ipv6 ? 1 : 0
 
  security_group_id = aws_security_group.nlb_security_group[0].id
  description       = "Allow public IPv6 HTTPS traffic to NLB. Required for IPv6 client access."
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv6         = "::/0"
}
 
# Ingress rule to allow worker nodes to receive traffic from NLB
resource "aws_vpc_security_group_ingress_rule" "workers_from_nlb" {
  count = var.enable_ipv6 && var.workers_security_group_id == null ? 1 : 0
 
  security_group_id            = aws_security_group.workers_security_group[0].id
  description                  = "Allow worker nodes to receive traffic from NLB on all ports"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.nlb_security_group[0].id
}

################################################################################
# AWS Load Balancer Controller Auto-Created NLB Security Groups
# Discover and add inbound rules to k8s-* SGs created by the controller
################################################################################

# Discover all NLBs tagged with the cluster name (created by AWS Load Balancer Controller)
data "aws_lbs" "controller_created_nlbs" {
  count = var.manage_controller_created_nlb_security_groups ? 1 : 0

  tags = {
    "elbv2.k8s.aws/cluster" = local.cluster_name
  }
}

# Get details for each discovered NLB
data "aws_lb" "controller_created_nlbs" {
  for_each = var.manage_controller_created_nlb_security_groups ? {
    for arn in try(data.aws_lbs.controller_created_nlbs[0].arns, []) : arn => arn
  } : {}

  arn = each.value
}

# Collect all security group IDs attached to discovered NLBs
locals {
  controller_created_nlb_sg_ids = distinct(flatten([
    for lb in values(data.aws_lb.controller_created_nlbs) : (
      lb.load_balancer_type == "network" ? lb.security_groups : []
    )
  ]))
}

# Fetch details for each security group to get the name
data "aws_security_group" "controller_created_nlb_sgs" {
  for_each = var.manage_controller_created_nlb_security_groups ? {
    for sg_id in local.controller_created_nlb_sg_ids : sg_id => sg_id
  } : {}

  id = each.value
}

# Filter to only k8s-* security groups (created by the controller, not pre-existing)
locals {
  controller_nlb_security_groups = tomap({
    for sg_id, sg in data.aws_security_group.controller_created_nlb_sgs : sg_id => sg
    if can(regex("^k8s-", sg.name))
  })
}

# Create a matrix of (security_group_id, port, cidr) for each inbound rule
locals {
  controller_nlb_ingress_matrix = {
    for combo in setproduct(
      keys(local.controller_nlb_security_groups),
      var.controller_nlb_security_group_inbound_ports,
      var.controller_nlb_security_group_inbound_cidrs
    ) :
    "${combo[0]}|${combo[1]}|${combo[2]}" => {
      security_group_id = combo[0]
      port              = combo[1]
      cidr              = combo[2]
      is_ipv6           = can(regex(":", combo[2]))
    }
  }
}

# Add inbound rules to controller-created NLB security groups
resource "aws_vpc_security_group_ingress_rule" "controller_nlb" {
  for_each = var.manage_controller_created_nlb_security_groups ? local.controller_nlb_ingress_matrix : {}

  security_group_id = each.value.security_group_id
  description       = "Allow ${each.value.is_ipv6 ? "IPv6" : "IPv4"} inbound traffic on port ${each.value.port} to Contour/Envoy NLB"
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value.is_ipv6 ? null : each.value.cidr
  cidr_ipv6         = each.value.is_ipv6 ? each.value.cidr : null

  tags = merge(local.tags, { "Name" : "controller-nlb-ingress-${each.value.port}" })
}