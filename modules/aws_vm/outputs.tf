output "private_ip_address" {
  value = var.create_vm ? aws_instance.vm.0.private_ip : ""
}

output "public_ip_address" {
  value = var.create_vm ? aws_instance.vm.0.public_ip : ""
}

output "admin_username" {
  value = var.create_vm ? local.vm_admin : ""
}

output "private_dns" {
  value = var.create_vm ? aws_instance.vm.0.private_dns : ""
}

output "public_dns" {
  value = var.create_vm ? aws_instance.vm.0.public_dns : ""
}
