locals {
    max_subnet_length = max(
        length(var.subnets["private"]),
        length(var.subnets["database"]),
    )
    nat_gateway_count = var.single_nat_gateway ? 1 : local.max_subnet_length

    vpc_id = var.vpc_id == null ? aws_vpc.byo[0].id : data.aws_vpc.byo[0].id
    public_subnets = var.existing_subnet_ids != null ? data.aws_subnet.byo_public.*.id : aws_subnet.public.*.id
}

data "aws_vpc" "byo" {
  count = var.vpc_id == null ? 0 : 1
  id    = var.vpc_id
}

resource "aws_vpc" "byo" {
  count      = var.vpc_id == null ? 1 : 0
  cidr_block = var.cidr
    tags = merge(
    {
      "Name" = format("%s", "${var.name}-vpc")
    },
    var.tags,
  )
}

data "aws_subnet" "byo_public" {
  count = length(var.existing_subnet_ids) == 0 ? 0 : length(var.existing_subnet_ids["public"])
  id    = element(var.existing_subnet_ids["public"], count.index)
}

data "aws_subnet" "byo_private" {
  count = length(var.existing_subnet_ids) == 0 ? 0 : length(var.existing_subnet_ids["private"])
  id    = element(var.existing_subnet_ids["private"], count.index)
}

data "aws_subnet" "byo_database" {
  count = length(var.existing_subnet_ids) == 0 ? 0 : length(var.existing_subnet_ids["database"])
  id    = element(var.existing_subnet_ids["database"], count.index)
}

resource "aws_subnet" "public" {
  count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["public"], count.index)
  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.name)
    },
    var.tags,
    var.public_subnet_tags,
  )
}

###################
# Internet Gateway
###################
resource "aws_internet_gateway" "this" {
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0

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
#   count = length(local.public_subnets) > 0 ? 1 : 0
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" = format("%s-${var.public_subnet_suffix}", var.name)
    },
    var.tags,
  )
}

resource "aws_route" "public_internet_gateway" {
  count = length(var.existing_subnet_ids) == 0 ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id

  timeouts {
    create = "5m"
  }
}

resource "aws_route_table_association" "public" {
  count = var.existing_subnet_ids == null ? length(var.subnets["public"]) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

resource "aws_subnet" "private" {
  count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["private"], count.index)
  
  tags = merge(
    {
      "Name" = format("%s-${var.private_subnet_suffix}", var.name)
    },
    var.tags,
  )
}

#################
# Private routes
# There are as many routing tables as the number of NAT gateways
#################
resource "aws_route_table" "private" {
  count = length(var.existing_subnet_ids) == 0 ? local.nat_gateway_count : 0

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
  )
}

resource "aws_route_table_association" "private" {

  count = var.existing_subnet_ids == null ? length(var.subnets["private"]) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

resource "aws_subnet" "database" {
  count      = var.existing_subnet_ids == null ? length(var.subnets["database"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["database"], count.index)

  tags = merge(
    {
      "Name" = format("%s", "${var.name}-database-subnet")
    },
    var.tags,
  )
}

#################
# Database routes
#################
resource "aws_route_table" "database" {
  count = length(var.existing_subnet_ids) == 0 && length(var.subnets["database"]) > 0  ? length(var.subnets["database"]) : 0

  vpc_id = local.vpc_id

  tags = merge(
    {
      "Name" =  format(
        "%s-${var.database_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
    },
    var.tags,
  )
}

resource "aws_eip" "nat" {
  count      = length(var.existing_subnet_ids) == 0 ? local.nat_gateway_count : 0

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
