output "private_ip_address" {
  value = var.create_vm ? aws_instance.vm.0.private_ip : null
}

output "public_ip_address" {
  value = var.create_vm ? aws_instance.vm.0.public_ip : null
}

output "admin_username" {
  value = var.create_vm ? var.vm_admin : ""
}

output "private_dns" {
  value = var.create_vm ? aws_instance.vm.0.private_dns : null
}

output "public_dns" {
  value = var.create_vm ? aws_instance.vm.0.public_dns : null
}
