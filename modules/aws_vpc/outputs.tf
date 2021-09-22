#vpc_id
output "vpc_id" {
  description = "VPC id"
  value       = local.vpc_id
}

#subnet_ids
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = var.vpc_private_enabled ? null : local.existing_public_subnets ? data.aws_subnet.public.*.id : aws_subnet.public.*.id
}

output "public_subnet_azs" {
  description = "List of public subnet AZs"
  value       = var.vpc_private_enabled ? null : local.existing_public_subnets ? data.aws_subnet.public.*.availability_zone : aws_subnet.public.*.availability_zone
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of public subnets"
  value       = local.existing_public_subnets ? data.aws_subnet.public.*.cidr_block : aws_subnet.public.*.cidr_block
}


output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = local.existing_private_subnets ? data.aws_subnet.private.*.id : aws_subnet.private.*.id
}

output "private_subnet_azs" {
  description = "List of private subnet AZs"
  value       = local.existing_private_subnets ? data.aws_subnet.private.*.availability_zone : aws_subnet.private.*.availability_zone
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of private subnets"
  value       = local.existing_private_subnets ? data.aws_subnet.private.*.cidr_block : aws_subnet.private.*.cidr_block
}


output "database_subnets" {
  description = "List of IDs of database subnets"
  value       = local.existing_database_subnets ? data.aws_subnet.database.*.id : aws_subnet.database.*.id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = var.vpc_private_enabled ? null : var.existing_nat_id == null ? aws_eip.nat.*.public_ip : data.aws_nat_gateway.nat_gateway.*.public_ip
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = var.vpc_private_enabled ? null : aws_route_table.public.*.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private.*.id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"
  value       = var.vpc_id == null ? var.cidr : data.aws_vpc.vpc[0].cidr_block
}
