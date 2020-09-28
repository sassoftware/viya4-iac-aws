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

resource "aws_key_pair" "admin" {
  count      = var.create_vm ? 1 : 0
  key_name   = "${var.name}-vmadmin"
  public_key = file(var.ssh_public_key)
  tags       = var.tags
}

data "null_data_source" "ebs_disk" {
  count = var.data_disk_count
}

resource "aws_instance" "vm" {
  count               = var.create_vm ? 1 : 0
  ami                 = data.aws_ami.centos.id
  instance_type       = var.machine_type
  user_data           = var.user_data
  key_name = aws_key_pair.admin[0].key_name

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
