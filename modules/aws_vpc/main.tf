# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# This is customized based on - https://github.com/terraform-aws-modules/terraform-aws-vpc

locals {
  vpc_id           = var.vpc_id == null ? aws_vpc.vpc[0].id : data.aws_vpc.vpc[0].id
  existing_subnets = length(var.existing_subnet_ids) > 0 ? true : false

  existing_public_subnets        = local.existing_subnets && contains(keys(var.existing_subnet_ids), "public") ? (length(var.existing_subnet_ids["public"]) > 0 ? true : false) : false
  existing_private_subnets       = local.existing_subnets && contains(keys(var.existing_subnet_ids), "private") ? (length(var.existing_subnet_ids["private"]) > 0 ? true : false) : false
  existing_database_subnets      = local.existing_subnets && contains(keys(var.existing_subnet_ids), "database") ? (length(var.existing_subnet_ids["database"]) > 0 ? true : false) : false
  existing_control_plane_subnets = local.existing_subnets && contains(keys(var.existing_subnet_ids), "control_plane") ? (length(var.existing_subnet_ids["control_plane"]) > 0 ? true : false) : false

  #  public_subnets  = local.existing_public_subnets ? data.aws_subnet.public : aws_subnet.public # not used keeping for ref
  private_subnets       = local.existing_private_subnets ? data.aws_subnet.private : aws_subnet.private
  control_plane_subnets = local.existing_control_plane_subnets ? data.aws_subnet.control_plane : aws_subnet.control_plane

  # Use private subnets if we are not creating db subnets and there are no existing db subnets
  database_subnets = local.existing_database_subnets ? data.aws_subnet.database : element(concat(aws_subnet.database[*].id, tolist([""])), 0) != "" ? aws_subnet.database : local.private_subnets

  byon_tier     = var.vpc_id == null ? 0 : local.existing_private_subnets ? (var.raw_sec_group_id == null && var.cluster_security_group_id == null && var.workers_security_group_id == null) ? 2 : 3 : 1
  byon_scenario = local.byon_tier

  create_nat_gateway = (local.byon_scenario == 0 || local.byon_scenario == 1) ? true : false
  create_subnets     = (local.byon_scenario == 0 || local.byon_scenario == 1) ? true : false
}

data "aws_vpc" "vpc" {
  count = var.vpc_id == null ? 0 : 1
  id    = var.vpc_id
}

######
# VPC
######
resource "aws_vpc" "vpc" {
  count                = var.vpc_id == null ? 1 : 0
  cidr_block           = var.cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  tags = merge(
    {
      "Name" = format("%s", "${var.name}-vpc")
    },
    var.tags,
  )
}

######
# Additional CIDR association
######
resource "aws_vpc_ipv4_cidr_block_association" "additional_cidr" {
  count      = var.enable_nist_features == true ? 4 : 0
  vpc_id     = aws_vpc.vpc[0].id
  cidr_block = element(var.additional_cidr_ranges, count.index)
}

resource "aws_vpc_endpoint" "private_endpoints" {
  for_each            = var.vpc_private_endpoints_enabled ? var.vpc_private_endpoints : {}
  vpc_id              = local.vpc_id
  service_name        = "com.amazonaws.${var.region}.${each.key}"
  vpc_endpoint_type   = each.value
  security_group_ids  = each.value == "Interface" ? [var.security_group_id] : null
  private_dns_enabled = each.value == "Interface" ? each.key != "s3" ? true : null : false

  tags = merge(
    {
      "Name" = format("%s", "${var.name}-private-endpoint-${each.key}")
    },
    var.tags,
  )

  subnet_ids = each.value == "Interface" ? [
    for subnet in local.private_subnets : subnet.id
  ] : null
}

data "aws_subnet" "public" {
  count = local.existing_public_subnets ? length(var.existing_subnet_ids["public"]) : 0
  id    = element(var.existing_subnet_ids["public"], count.index)
}

data "aws_subnet" "private" {
  count = local.existing_private_subnets ? length(var.existing_subnet_ids["private"]) : 0
  id    = element(var.existing_subnet_ids["private"], count.index)
}

data "aws_subnet" "database" {
  count = local.existing_database_subnets ? length(var.existing_subnet_ids["database"]) : 0
  id    = element(var.existing_subnet_ids["database"], count.index)
}

data "aws_subnet" "control_plane" {
  count = local.existing_control_plane_subnets ? length(var.existing_subnet_ids["control_plane"]) : 0
  id    = element(var.existing_subnet_ids["control_plane"], count.index)
}
################
# Public subnet
################
resource "aws_subnet" "public" {
  count                   = local.existing_public_subnets ? 0 : local.create_subnets ? length(var.subnets["public"]) : 0
  vpc_id                  = local.vpc_id
  cidr_block              = element(var.subnets["public"], count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.public_subnet_azs, count.index))) > 0 ? element(var.public_subnet_azs, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.public_subnet_azs, count.index))) == 0 ? element(var.public_subnet_azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch
  depends_on              = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        element(var.public_subnet_azs, count.index),
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = var.existing_nat_id == null ? local.create_nat_gateway ? 1 : 0 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
  )
}

################
# Publiс routes
################
resource "aws_route_table" "public" {
  count  = local.existing_public_subnets ? 0 : local.create_subnets ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        element(var.public_subnet_azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = var.existing_nat_id == null ? local.create_nat_gateway ? 1 : 0 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

##########################
# Route table association
##########################
resource "aws_route_table_association" "private" {
  count = local.existing_private_subnets ? 0 : length(var.subnets["private"])

  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, 0)
}

resource "aws_route_table_association" "public" {
  count = local.existing_public_subnets ? 0 : local.create_subnets ? length(var.subnets["public"]) : 0

  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = element(aws_route_table.public[*].id, 0)
}

resource "aws_route_table_association" "database" {
  count = local.existing_database_subnets ? 0 : local.create_subnets ? length(var.subnets["database"]) : 0

  subnet_id      = element(aws_subnet.database[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, 0)
}

resource "aws_route_table_association" "control_plane" {
  count = local.existing_control_plane_subnets ? 0 : local.create_subnets ? length(var.subnets["control_plane"]) : 0

  subnet_id      = element(aws_subnet.control_plane[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, 0)
}
#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count                = local.existing_private_subnets ? 0 : length(var.subnets["private"])
  vpc_id               = local.vpc_id
  cidr_block           = element(var.subnets["private"], count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.private_subnet_azs, count.index))) > 0 ? element(var.private_subnet_azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.private_subnet_azs, count.index))) == 0 ? element(var.private_subnet_azs, count.index) : null
  depends_on              = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]
  tags = merge(
    {
      "Name" = format(
        "%s-${var.private_subnet_suffix}-%s",
        var.name,
        element(var.private_subnet_azs, count.index),
      )
    },
    var.tags,
    var.private_subnet_tags,
  )
}

#################
# Private routes
# There are as many routing tables as the number of NAT gateways
#################
resource "aws_route_table" "private" {
  count = local.existing_private_subnets ? 0 : 1

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-${var.private_subnet_suffix}-%s",
        var.name,
        element(var.private_subnet_azs, count.index),
      )
    },
    var.tags,
  )
}

##################
# Database subnet
##################
resource "aws_subnet" "database" {
  count                = local.existing_database_subnets ? 0 : local.create_subnets ? length(var.subnets["database"]) : 0
  vpc_id               = local.vpc_id
  cidr_block           = element(var.subnets["database"], count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.database_subnet_azs, count.index))) > 0 ? element(var.database_subnet_azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.database_subnet_azs, count.index))) == 0 ? element(var.database_subnet_azs, count.index) : null
  depends_on              = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]
  tags = merge(
    {
      "Name" = format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.database_subnet_azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_db_subnet_group" "database" {
  count = local.existing_database_subnets == false ? local.create_subnets ? contains(keys(var.subnets), "database") ? length(var.subnets["database"]) > 0 ? 1 : 0 : 0 : 0 : 0

  name        = lower(var.name)
  description = "Database subnet group for ${var.name}"
  subnet_ids  = aws_subnet.database[*].id
  depends_on              = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]
  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
  )
}

#################
# Control Plane subnet
#################
resource "aws_subnet" "control_plane" {
  count                = local.existing_control_plane_subnets ? 0 : length(var.subnets["control_plane"])
  vpc_id               = local.vpc_id
  cidr_block           = element(var.subnets["control_plane"], count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.control_plane_subnet_azs, count.index))) > 0 ? element(var.control_plane_subnet_azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.control_plane_subnet_azs, count.index))) == 0 ? element(var.control_plane_subnet_azs, count.index) : null
  depends_on              = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]
  tags = merge(
    {
      "Name" = format(
        "%s-${var.control_plane_subnet_suffix}-%s",
        var.name,
        element(var.control_plane_subnet_azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_eip" "nat" {
  count = var.existing_nat_id == null ? local.create_nat_gateway ? 1 : 0 : 0

  domain = "vpc"

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.public_subnet_azs, count.index),
      )
    },
    var.tags,
  )
}

data "aws_nat_gateway" "nat_gateway" {
  count = var.existing_nat_id != null ? 1 : 0
  id    = var.existing_nat_id # alt. support vpc_id or subnet_id where NAT
}

resource "aws_nat_gateway" "nat_gateway" {
  count = var.existing_nat_id == null ? local.create_nat_gateway ? 1 : 0 : 0

  allocation_id = element(aws_eip.nat[*].id, 0)
  subnet_id     = local.existing_public_subnets ? element(data.aws_subnet.public[*].id, 0) : element(aws_subnet.public[*].id, 0)

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.public_subnet_azs, 0),
      )
    },
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = var.existing_nat_id == null ? local.create_nat_gateway ? 1 : 0 : 0

  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gateway[*].id, count.index)

  timeouts {
    create = "5m"
  }
}

#################
# ENI subnets creation as per AWS NG architecture
#################
resource "aws_subnet" "eni" {
  count      = var.enable_nist_features == true ? 2 : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["eni"], count.index)
  #availability_zone       = element(var.availability_zones, count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.eni_subnet_azs, count.index))) > 0 ? element(var.eni_subnet_azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.eni_subnet_azs, count.index))) == 0 ? element(var.eni_subnet_azs, count.index) : null
  depends_on           = [aws_vpc.vpc, aws_vpc_ipv4_cidr_block_association.additional_cidr]
  tags = merge(
    {
      "Name" = format("%s", "${var.name}-eni-${count.index}"),
      "type" = var.enable_nist_features == true ? "awsng-spoke-eni" : null
    },
    var.tags
  )
}

#################
# ENI subnets association with private route table #####
#################
resource "aws_route_table_association" "eni" {
  count = var.enable_nist_features == true ? length(aws_subnet.eni) : 0
  subnet_id      = element(aws_subnet.eni[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, 0)
}

#################
# VPC attachment for HUB integration #####
#################
resource "aws_networkmanager_vpc_attachment" "vpc_attach" {
  count           = var.enable_nist_features == true ? 1 : 0
  subnet_arns     = aws_subnet.eni[*].arn
  core_network_id = var.core_network_id
  vpc_arn         = aws_vpc.vpc[0].arn
  tags = {
    segment = var.hub
    Name    = "${var.name}-${var.hub_environment}"
  }
}

#################
# Route to Core network device from Private route table #####
#################
resource "aws_route" "private_core_network" {
  count                  = var.enable_nist_features == true ? 1 : 0
  route_table_id         = aws_route_table.private[0].id
  destination_cidr_block = "0.0.0.0/0"
  core_network_arn       = var.core_network_arn
  depends_on             = [aws_networkmanager_vpc_attachment.vpc_attach]

  timeouts {
    create = "5m"
  }
}
