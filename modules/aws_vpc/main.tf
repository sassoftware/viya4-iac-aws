locals {
  vpc_id           = var.vpc_id == null ? aws_vpc.vpc[0].id : data.aws_vpc.vpc[0].id
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

data "aws_subnet" "public" {
  count = contains(keys(var.existing_subnet_ids), "public") ? length(var.existing_subnet_ids["public"]) > 0 ? length(var.existing_subnet_ids["public"]) : 0 : 0
  id    = element(var.existing_subnet_ids["public"], count.index)
}

data "aws_subnet" "private" {
  count = contains(keys(var.existing_subnet_ids), "private") ? length(var.existing_subnet_ids["private"]) > 0 ? length(var.existing_subnet_ids["private"]) : 0 : 0
  id    = element(var.existing_subnet_ids["private"], count.index)
}

data "aws_subnet" "database" {
  count = contains(keys(var.existing_subnet_ids), "database") ? length(var.existing_subnet_ids["database"]) > 0 ? length(var.existing_subnet_ids["database"]) : 0 : 0
  id    = element(var.existing_subnet_ids["database"], count.index)
}

################
# Public subnet
################
resource "aws_subnet" "public" {
  count                   = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0
  vpc_id                  = local.vpc_id
  cidr_block              = element(var.subnets["public"], count.index)
  availability_zone       = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
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
  count =  length(var.existing_subnet_ids) == 0 && var.existing_nat_id == null ? 1 : 0

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
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0
  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.public_subnet_tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.existing_subnet_ids) == 0 && var.existing_nat_id == null ? 1 : 0

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

  count = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0

  subnet_id      = length(var.existing_subnet_ids) == 0 ? element(aws_subnet.private.*.id, count.index) : element(data.aws_subnet.private.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, 0)
}

resource "aws_route_table_association" "public" {
  count = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0

  subnet_id      = length(var.existing_subnet_ids) == 0 ? element(aws_subnet.public.*.id, count.index) : element(data.aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "database" {
  count = length(var.existing_subnet_ids) == 0 ? length(var.subnets["database"]) : 0

  subnet_id = element(aws_subnet.database.*.id, count.index)
  route_table_id = element(
      coalescelist(aws_route_table.private.*.id), 0)
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count                = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0
  vpc_id               = local.vpc_id
  cidr_block           = element(var.subnets["private"], count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

  tags = merge(
    {
      "Name" = format(
        "%s-${var.private_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
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
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format(
        "%s-${var.private_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
    var.private_subnet_tags,
  )
}

##################
# Database subnet
##################
resource "aws_subnet" "database" {
  count                = length(var.existing_subnet_ids) == 0 ? length(var.subnets["database"]) : 0
  vpc_id               = local.vpc_id
  cidr_block           = element(var.subnets["database"], count.index)
  availability_zone    = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

  tags = merge(
    {
      "Name" = format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_db_subnet_group" "database" {
  count = length(var.existing_subnet_ids) == 0 && length(var.subnets["database"]) > 0 ? 1 : 0

  name        = lower(var.name)
  description = "XXX Database subnet group for ${var.name} XXXXX"
  subnet_ids  = aws_subnet.database.*.id

  tags = merge(
    {
      "Name" = format("%s", var.name)
    },
    var.tags,
  )
}

resource "aws_eip" "nat" {
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0

  vpc = true

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
  )
}

data "aws_nat_gateway" "nat" {
  count = var.existing_nat_id != null ? 1 : 0
  id = var.existing_nat_id # alt. support vpc_id or subnet_id where NAT 
}

resource "aws_nat_gateway" "this" {
  count = var.existing_nat_id != null ? 0 : 1

  allocation_id = element(aws_eip.nat.*.id, 0)
  subnet_id = length(var.existing_subnet_ids) == 0 ? element(aws_subnet.public.*.id,0) : element(data.aws_subnet.public.*.id, 0)

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, 0),
      )
    },
    var.tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route" "private_nat_gateway" {
  count = length(var.existing_subnet_ids) == 0  ? 1 : 0

  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this.*.id, count.index)

  timeouts {
    create = "5m"
  }
}
