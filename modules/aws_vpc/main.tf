locals {
    max_subnet_length = length(var.existing_subnet_ids) == 0 ? max(
        length(var.subnets["private"]),
        length(var.subnets["database"]),
    ) : max(length(data.aws_subnet.byo_private.*.id), length(data.aws_subnet.byo_database.*.id))
    nat_gateway_count = var.single_nat_gateway ? 1 : local.max_subnet_length

    vpc_id = var.vpc_id == null ? aws_vpc.byo[0].id : data.aws_vpc.byo[0].id
    public_subnets = length(var.existing_subnet_ids) == 0 ? data.aws_subnet.byo_public.*.id : aws_subnet.public.*.id
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

################
# Public subnet
################
resource "aws_subnet" "public" {
  count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["public"], count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

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
      "Name" = format(
        "%s-${var.public_subnet_suffix}-%s",
        var.name,
        element(var.azs, count.index),
      )
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

resource "aws_route_table_association" "private" {

  count = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "public" {
  count = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.public[0].id
}

#################
# Private subnet
#################
resource "aws_subnet" "private" {
  count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["private"], count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null
  
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

##################
# Database subnet
##################
resource "aws_subnet" "database" {
  count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["database"]) : 0
  vpc_id     = local.vpc_id
  cidr_block = element(var.subnets["database"], count.index)
  availability_zone               = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) > 0 ? element(var.azs, count.index) : null
  availability_zone_id            = length(regexall("^[a-z]{2}-", element(var.azs, count.index))) == 0 ? element(var.azs, count.index) : null

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
  # count = var.create_vpc && length(var.database_subnets) > 0 && var.create_database_subnet_group ? 1 : 0
  count      = length(var.existing_subnet_ids) == 0 && length(var.subnets["database"]) > 0 ? 1 : 0

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

########################
# Public Network ACLs
########################
# resource "aws_network_acl" "public" {
#   # count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? 1 : 0
#   count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["public"]) : 0
#   vpc_id     = local.vpc_id
#   subnet_ids = aws_subnet.public.*.id

#   tags = merge(
#     {
#       "Name" = format("%s-${var.public_subnet_suffix}", var.name)
#     },
#     var.tags,
#     var.public_acl_tags,
#   )
# }

# resource "aws_network_acl_rule" "public_inbound" {
#   count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_inbound_acl_rules) : 0

#   network_acl_id = aws_network_acl.public[0].id

#   egress          = false
#   rule_number     = var.public_inbound_acl_rules[count.index]["rule_number"]
#   rule_action     = var.public_inbound_acl_rules[count.index]["rule_action"]
#   from_port       = lookup(var.public_inbound_acl_rules[count.index], "from_port", null)
#   to_port         = lookup(var.public_inbound_acl_rules[count.index], "to_port", null)
#   icmp_code       = lookup(var.public_inbound_acl_rules[count.index], "icmp_code", null)
#   icmp_type       = lookup(var.public_inbound_acl_rules[count.index], "icmp_type", null)
#   protocol        = var.public_inbound_acl_rules[count.index]["protocol"]
#   cidr_block      = lookup(var.public_inbound_acl_rules[count.index], "cidr_block", null)
#   ipv6_cidr_block = lookup(var.public_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
# }

# resource "aws_network_acl_rule" "public_outbound" {
#   count = var.create_vpc && var.public_dedicated_network_acl && length(var.public_subnets) > 0 ? length(var.public_outbound_acl_rules) : 0

#   network_acl_id = aws_network_acl.public[0].id

#   egress          = true
#   rule_number     = var.public_outbound_acl_rules[count.index]["rule_number"]
#   rule_action     = var.public_outbound_acl_rules[count.index]["rule_action"]
#   from_port       = lookup(var.public_outbound_acl_rules[count.index], "from_port", null)
#   to_port         = lookup(var.public_outbound_acl_rules[count.index], "to_port", null)
#   icmp_code       = lookup(var.public_outbound_acl_rules[count.index], "icmp_code", null)
#   icmp_type       = lookup(var.public_outbound_acl_rules[count.index], "icmp_type", null)
#   protocol        = var.public_outbound_acl_rules[count.index]["protocol"]
#   cidr_block      = lookup(var.public_outbound_acl_rules[count.index], "cidr_block", null)
#   ipv6_cidr_block = lookup(var.public_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
# }

# #######################
# # Private Network ACLs
# #######################
# resource "aws_network_acl" "private" {
#   # count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? 1 : 0
#   count      = length(var.existing_subnet_ids) == 0 ? length(var.subnets["private"]) : 0

#   vpc_id     = local.vpc_id
#   subnet_ids = aws_subnet.private.*.id

#   tags = merge(
#     {
#       "Name" = format("%s-${var.private_subnet_suffix}", var.name)
#     },
#     var.tags,
#     var.private_acl_tags,
#   )
# }

# resource "aws_network_acl_rule" "private_inbound" {
#   count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_inbound_acl_rules) : 0

#   network_acl_id = aws_network_acl.private[0].id

#   egress          = false
#   rule_number     = var.private_inbound_acl_rules[count.index]["rule_number"]
#   rule_action     = var.private_inbound_acl_rules[count.index]["rule_action"]
#   from_port       = lookup(var.private_inbound_acl_rules[count.index], "from_port", null)
#   to_port         = lookup(var.private_inbound_acl_rules[count.index], "to_port", null)
#   icmp_code       = lookup(var.private_inbound_acl_rules[count.index], "icmp_code", null)
#   icmp_type       = lookup(var.private_inbound_acl_rules[count.index], "icmp_type", null)
#   protocol        = var.private_inbound_acl_rules[count.index]["protocol"]
#   cidr_block      = lookup(var.private_inbound_acl_rules[count.index], "cidr_block", null)
#   ipv6_cidr_block = lookup(var.private_inbound_acl_rules[count.index], "ipv6_cidr_block", null)
# }

# resource "aws_network_acl_rule" "private_outbound" {
#   count = var.create_vpc && var.private_dedicated_network_acl && length(var.private_subnets) > 0 ? length(var.private_outbound_acl_rules) : 0

#   network_acl_id = aws_network_acl.private[0].id

#   egress          = true
#   rule_number     = var.private_outbound_acl_rules[count.index]["rule_number"]
#   rule_action     = var.private_outbound_acl_rules[count.index]["rule_action"]
#   from_port       = lookup(var.private_outbound_acl_rules[count.index], "from_port", null)
#   to_port         = lookup(var.private_outbound_acl_rules[count.index], "to_port", null)
#   icmp_code       = lookup(var.private_outbound_acl_rules[count.index], "icmp_code", null)
#   icmp_type       = lookup(var.private_outbound_acl_rules[count.index], "icmp_type", null)
#   protocol        = var.private_outbound_acl_rules[count.index]["protocol"]
#   cidr_block      = lookup(var.private_outbound_acl_rules[count.index], "cidr_block", null)
#   ipv6_cidr_block = lookup(var.private_outbound_acl_rules[count.index], "ipv6_cidr_block", null)
# }

resource "aws_nat_gateway" "this" {
  # count = var.create_vpc && var.enable_nat_gateway ? local.nat_gateway_count : 0
  count = var.enable_nat_gateway ? local.nat_gateway_count : 0

  allocation_id = element(
    aws_eip.nat.*.id, #local.nat_gateway_ips,
    var.single_nat_gateway ? 0 : count.index,
  )
  subnet_id = length(var.existing_subnet_ids) == 0 ? element(
    aws_subnet.public.*.id,
    var.single_nat_gateway ? 0 : count.index,
  ) : element(var.existing_subnet_ids["public"], var.single_nat_gateway ? 0 : count.index,)

  tags = merge(
    {
      "Name" = format(
        "%s-%s",
        var.name,
        element(var.azs, var.single_nat_gateway ? 0 : count.index),
      )
    },
    var.tags,
    # var.nat_gateway_tags,
  )

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat" {
  count      = local.nat_gateway_count

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
