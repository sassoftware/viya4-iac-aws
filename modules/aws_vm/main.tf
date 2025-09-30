# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Reference: https://github.com/terraform-providers/terraform-provider-aws

# Hack for assigning disk in a vm based on an index value.
locals {
  # local device_name is a list of device names used for attaching additional disks to the VM
  device_name = [
    # "/dev/sdb", - NOTE: These are skipped, Ubuntu Server 20.04 LTS
    # "/dev/sdc",         uses these for ephemeral storage.
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

# Data source to fetch the latest Ubuntu AMI ID from AWS Marketplace
data "aws_ami" "ubuntu" {
  # Canonical is the owner of the official Ubuntu images
  owners      = ["099720109477"] # Canonical
  most_recent = true

  # Filter to find the Ubuntu AMI by its name pattern
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  # Filter to ensure the AMI is of the correct architecture
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  # Filter to ensure the AMI uses hardware virtualization
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Filter to ensure the AMI's root device is of type EBS
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Resource to create an SSH key pair for accessing the VM
resource "aws_key_pair" "admin" {
  # The name of the key pair, unique within the AWS region
  key_name = "${var.name}-admin"
  # The public key material
  public_key = var.ssh_public_key
}

# Resource to provision an EC2 instance (VM) in AWS
resource "aws_instance" "vm" {
  # The AMI ID to use for the instance, fetched from the aws_ami data source
  ami = data.aws_ami.ubuntu.id
  # The instance type, e.g., t2.micro, specified in variables
  instance_type = var.vm_type
  # Cloud-init script for initializing the VM, if provided
  user_data = (var.cloud_init != "" ? var.cloud_init : null)
  # The key pair to use for SSH access, referencing the aws_key_pair resource
  key_name = aws_key_pair.admin.key_name
  # The availability zone for the instance, specified in variables
  availability_zone = var.data_disk_availability_zone

  # Network settings for the instance
  vpc_security_group_ids      = var.security_group_ids
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.create_public_ip

  # Configuration for the root block device (EBS volume)
  root_block_device {
    # The type of the volume, e.g., gp2, io1, specified in variables
    volume_type = var.os_disk_type
    # The size of the volume in GiB
    volume_size = var.os_disk_size
    # Whether to delete the volume on instance termination
    delete_on_termination = var.os_disk_delete_on_termination
    # The IOPS (Input/Output Operations Per Second) for the volume, if applicable
    iops = var.os_disk_iops
    # Whether to enable encryption for the volume
    encrypted = var.enable_ebs_encryption
    # Tags to apply to the volume, merging static and variable tags
    tags = merge(
      {
        Name : "${var.name}-root-vol"
      },
      var.tags
    )
  }

  # Tags to apply to the instance, merging static and variable tags
  tags = merge(var.tags, tomap({ Name : "${var.name}-vm" }))

  # Lifecycle settings for the resource
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because a management agent
      # updates these based on some ruleset managed elsewhere.
      ami,
    ]
  }

}

# Resource to allocate an Elastic IP address for the VM
resource "aws_eip" "eip" {
  # Count is set based on whether a public IP is to be created
  count = var.create_public_ip ? 1 : 0
  # The domain for the Elastic IP, "vpc" for VPC-based instances
  domain = "vpc"
  # The instance to associate the Elastic IP with
  instance = aws_instance.vm.id
  # Tags to apply to the Elastic IP, merging static and variable tags
  tags = merge(var.tags, tomap({ Name : "${var.name}-eip" }))
}

# Resource to attach additional EBS volumes to the VM
resource "aws_volume_attachment" "data-volume-attachment" {
  # Count is set to the number of data disks to attach
  count = var.data_disk_count
  # The device name to expose to the instance, based on the local device_name list
  device_name = element(local.device_name, count.index)
  # The instance to attach the volume to
  instance_id = aws_instance.vm.id
  # The volume to attach, from the aws_ebs_volume resource
  volume_id = element(aws_ebs_volume.raid_disk[*].id, count.index)
}

# Resource to create additional EBS volumes for the VM
resource "aws_ebs_volume" "raid_disk" {
  # Count is set to the number of data disks to create
  count = var.data_disk_count
  # The availability zone for the volume, specified in variables
  availability_zone = var.data_disk_availability_zone
  # The size of the volume in GiB
  size = var.data_disk_size
  # The type of the volume, e.g., gp2, io1, specified in variables
  type = var.data_disk_type
  # The IOPS (Input/Output Operations Per Second) for the volume, if applicable
  iops = var.data_disk_iops
  # Tags to apply to the volume, merging static and variable tags
  tags = merge(var.tags, tomap({ Name : "${var.name}-vm" }))
  # Whether to enable encryption for the volume
  encrypted = var.enable_ebs_encryption
}

# Reference the feature flag variable name, an example reference to suppress TFLint warning
resource "terraform_data" "example" {

  provisioner "local-exec" {
    command = "echo The enable_nist_features flag value is: ${var.enable_nist_features}"
  }
}
