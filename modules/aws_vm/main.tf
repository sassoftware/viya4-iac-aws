# Reference: https://github.com/terraform-providers/terraform-provider-aws

# Hack for assigning disk in a vm based on an index value. 
locals {
  device_name = [
    # "/dev/sdb", - NOTE: These are skipped, Ubuntu Server 20.04 LTS
    # "/dev/sdc",         uses these for ephmeral storage.
    "/dev/sdd",
    "/dev/sde",
    "/dev/sdf",
    "/dev/sdg",
    "/dev/sdh",
    "/dev/sdi",
    "/dev/sdj",
    "/dev/sdk",
    "/dev/sdl",
    "/dev/sdm",
    "/dev/sdn",
    "/dev/sdo",
    "/dev/sdp",
    "/dev/sdq",
    "/dev/sdr",
    "/dev/sds",
    "/dev/sdt",
    "/dev/sdu",
    "/dev/sdv",
    "/dev/sdw",
    "/dev/sdx",
    "/dev/sdy",
    "/dev/sdz"
  ]
}

data "aws_ami" "ubuntu" {
  owners      = ["099720109477"] # Canonical
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_key_pair" "admin" {
  key_name   = "${var.name}-admin"
  public_key = var.ssh_public_key
}

resource "aws_instance" "vm" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = var.vm_type
  user_data         = (var.cloud_init != "" ? var.cloud_init : null)
  key_name          = aws_key_pair.admin.key_name
  availability_zone = var.data_disk_availability_zone

  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.create_public_ip

  root_block_device {
    volume_type           = var.os_disk_type
    volume_size           = var.os_disk_size
    delete_on_termination = var.os_disk_delete_on_termination
    iops                  = var.os_disk_iops
    encrypted             = var.enable_ebs_encryption
  }

  tags = merge(var.tags, tomap({ Name : "${var.name}-vm" }))

}

resource "aws_eip" "eip" {
  count    = var.create_public_ip ? 1 : 0
  vpc      = true
  instance = aws_instance.vm.id
  tags     = merge(var.tags, tomap({ Name : "${var.name}-eip" }))
}

resource "aws_volume_attachment" "data-volume-attachment" {
  count       = var.data_disk_count
  device_name = element(local.device_name, count.index)
  instance_id = aws_instance.vm.id
  volume_id   = element(aws_ebs_volume.raid_disk.*.id, count.index)
}

resource "aws_ebs_volume" "raid_disk" {
  count             = var.data_disk_count
  availability_zone = var.data_disk_availability_zone
  size              = var.data_disk_size
  type              = var.data_disk_type
  iops              = var.data_disk_iops
  tags              = merge(var.tags, tomap({ Name : "${var.name}-vm" }))
  encrypted         = var.enable_ebs_encryption
}
