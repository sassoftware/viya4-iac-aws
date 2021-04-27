#vpc_id
output "vpc_id" {
  description = "VPC id"
  value       = local.vpc_id
}

#subnet_ids
output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = length(var.existing_subnet_ids) == 0 ? aws_subnet.public.*.id : data.aws_subnet.byo_public.*.id
}

output "private_subnets" {
  description = "List of IDs of private subnets"
  value       = length(var.existing_subnet_ids) == 0 ? aws_subnet.private.*.id : data.aws_subnet.byo_private.*.id
}

output "database_subnets" {
  description = "List of IDs of public subnets"
  value       = length(var.existing_subnet_ids) == 0 ? aws_subnet.database.*.id : data.aws_subnet.byo_database.*.id
}

output "nat_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat.*.public_ip
}

output "public_route_table_ids" {
  description = "List of IDs of public route tables"
  value       = aws_route_table.public.*.id
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables"
  value       = aws_route_table.private.*.id
}
