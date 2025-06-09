# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

#vpc_id
output "vpc_id" {
  description = "VPC id"
  value       = local.vpc_id
}

#subnet_ids
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = local.existing_public_subnets ? data.aws_subnet.public[*].id : aws_subnet.public[*].id
}

output "public_subnet_azs" {
  description = "List of availability zones for the public subnets"
  value       = local.existing_public_subnets ? data.aws_subnet.public[*].availability_zone : aws_subnet.public[*].availability_zone
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = local.existing_public_subnets ? data.aws_subnet.public[*].cidr_block : aws_subnet.public[*].cidr_block
}


output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = local.existing_private_subnets ? data.aws_subnet.private[*].id : aws_subnet.private[*].id
}

output "private_subnet_azs" {
  description = "List of availability zones for the private subnets"
  value       = local.existing_private_subnets ? data.aws_subnet.private[*].availability_zone : aws_subnet.private[*].availability_zone
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = local.existing_private_subnets ? data.aws_subnet.private[*].cidr_block : aws_subnet.private[*].cidr_block
}


output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = local.existing_database_subnets ? data.aws_subnet.database[*].id : local.database_subnets[*].id
}

output "control_plane_subnets" {
  description = "List of IDs of control plane subnets"
  value       = local.existing_control_plane_subnets ? data.aws_subnet.control_plane[*].id : local.control_plane_subnets[*].id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = var.existing_nat_id == null ? local.create_nat_gateway ? aws_eip.nat[*].public_ip : null : data.aws_nat_gateway.nat_gateway[*].public_ip
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = local.existing_public_subnets ? null : aws_route_table.public[*].id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = local.existing_private_subnets ? null : aws_route_table.private[*].id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"
  value       = var.vpc_id == null ? var.cidr : data.aws_vpc.vpc[0].cidr_block
}

output "byon_scenario" {
  description = "The BYO networking configuration (0,1,2, or 3) determined by the set of networking input values configured"
  value       = local.byon_scenario
}

output "create_nat_gateway" {
  description = "The networking configuration will create a NAT gateway"
  value       = local.create_nat_gateway
}
