# Reference: https://github.com/terraform-providers/terraform-provider-aws

# Hack for assigning disk in a vm based on an index value. 
locals {
  device_name = ["b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
}

data "aws_ami" "centos" {
  owners      = ["aws-marketplace"]
  most_recent = true

  filter {
    name   = "name"
    values = ["CentOS Linux 7 x86_64 HVM EBS *"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

data "null_data_source" "ebs_disk" {
  count = var.data_disk_count
}

resource "tls_private_key" "private_key" {
  count = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
}

data "tls_public_key" "public_key" {
  count = var.ssh_public_key == "" ? 1 : 0
  private_key_pem = element(coalescelist(tls_private_key.private_key.*.private_key_pem), 0)
}

locals {
  ssh_public_key = var.ssh_public_key != "" ? file(var.ssh_public_key) : element(coalescelist(data.tls_public_key.public_key.*.public_key_openssh, [""]), 0)
}

resource "aws_key_pair" "admin" {
  key_name = "${var.name}-admin"
  public_key = local.ssh_public_key
}

resource "aws_instance" "vm" {
  count         = var.create_vm ? 1 : 0
  ami           = data.aws_ami.centos.id
  instance_type = var.machine_type
  user_data     = (var.cloud_init != "" ? var.cloud_init : null)
  key_name      = aws_key_pair.admin.key_name

  vpc_security_group_ids = var.security_group_ids
  subnet_id = var.subnet_id

  root_block_device {
    volume_type = var.os_disk_type
    volume_size = var.os_disk_size
    delete_on_termination = var.os_disk_delete_on_termination
    iops = var.os_disk_iops
  }

  tags = merge(var.tags, map("Name", "${var.name}-vm"))

}
