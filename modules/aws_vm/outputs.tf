# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

output "private_ip_address" {
  description = "Private IP address associated with the VM."
  value       = aws_instance.vm.private_ip
}

output "public_ip_address" {
  description = "Public IP address associated with the VM."
  value       = var.create_public_ip ? coalesce(aws_eip.eip[0].public_ip, aws_instance.vm.public_ip) : null
}

output "admin_username" {
  description = "Admin username for the VM"
  value       = var.vm_admin
}

output "private_dns" {
  description = "Private DNS name assigned to the VM."
  value       = aws_instance.vm.private_dns
}

output "public_dns" {
  description = "Public DNS name assigned to the VM."
  value       = var.create_public_ip ? coalesce(aws_eip.eip[0].public_dns, aws_instance.vm.public_dns) : null
}
