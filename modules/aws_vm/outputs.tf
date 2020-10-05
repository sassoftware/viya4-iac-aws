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

output "private_key_pem" {
    value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.private_key_pem, [""]), 0): null
}

output "public_key_pem" {
    value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_pem, [""]), 0) : null
}

output "public_key_openssh" {
    value = var.ssh_public_key == "" ? element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0) : null
}
