# Copyright © 2021-2023, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

locals {
  rwx_filestore_endpoint = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? aws_efs_file_system.efs-fs[0].dns_name
    : var.storage_type == "ontap" ? aws_fsx_ontap_file_system.ontap-fs[0].dns_name : module.nfs[0].private_ip_address
  )
  rwx_filestore_path = (var.storage_type == "none"
    ? ""
    : var.storage_type == "ha" ? "/"
    : var.storage_type == "ontap" ? "/" : "/export"
  )
}

# ONTAP File System - https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_ontap_file_system

resource "aws_fsx_ontap_file_system" "ontap-fs" {

  count               = var.storage_type == "ontap" ? 1 : 0
  storage_capacity    = 1024
  deployment_type     = var.fsx_ontap_deployment_type

  # If deployment_type is SINGLE_AZ_1 then subnet_ids should have 1 subnet ID
  # If deployment_type is MULTI_AZ_1 then subnet_ids should have 2 subnet IDs. 
  # Only 2 subnet IDs maximum may be listed.
  subnet_ids          = var.fsx_ontap_deployment_type == "SINGLE_AZ_1" ? [module.vpc.private_subnets[0]] : module.vpc.private_subnets
  throughput_capacity = 512
  preferred_subnet_id = module.vpc.private_subnets[0]
  security_group_ids  = [local.workers_security_group_id]

  tags                            = merge(local.tags, { "Name" : "${var.prefix}-ontap" })
}

# ONTAP storage virtual machine and volume resources

resource "aws_fsx_ontap_storage_virtual_machine" "ontap-svm" {
  file_system_id = aws_fsx_ontap_file_system.ontap-fs[0].id
  name           = "ontap-svm"
}

# A default volume gets created with the svm, we may want another
# in order to configure desired attributes
resource "aws_fsx_ontap_volume" "vol1" {
  name                       = "vol1"
  junction_path              = "/vol1"
  size_in_megabytes          = 1024
  storage_efficiency_enabled = true
  storage_virtual_machine_id = aws_fsx_ontap_storage_virtual_machine.ontap-svm.id
}

# EFS File System - https://www.terraform.io/docs/providers/aws/r/efs_file_system.html
resource "aws_efs_file_system" "efs-fs" {
  count                           = var.storage_type == "ha" ? 1 : 0
  creation_token                  = "${var.prefix}-efs"
  performance_mode                = var.efs_performance_mode
  throughput_mode                 = var.efs_throughput_mode
  provisioned_throughput_in_mibps = var.efs_throughput_mode == "provisioned" ? var.efs_throughput_rate : null
  tags                            = merge(local.tags, { "Name" : "${var.prefix}-efs" })
  encrypted                       = var.enable_efs_encryption
}

# EFS Mount Target - https://www.terraform.io/docs/providers/aws/r/efs_mount_target.html
resource "aws_efs_mount_target" "efs-mt" {
  # NOTE - Testing. use num_azs = 2
  count           = var.storage_type == "ha" ? length(module.vpc.private_subnets) : 0
  file_system_id  = aws_efs_file_system.efs-fs[0].id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [local.workers_security_group_id]
}

# Defining the cloud-config to use
data "cloudinit_config" "jump" {
  count         = var.create_jump_vm ? 1 : 0
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content     = templatefile("${path.module}/files/cloud-init/jump/cloud-config", {
      mounts = (var.storage_type == "none"
        ? "[]"
        : jsonencode(
          ["${local.rwx_filestore_endpoint}:${local.rwx_filestore_path}",
            var.jump_rwx_filestore_path,
            "nfs",
            "rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport",
            "0",
            "0"
        ])
      )
      rwx_filestore_endpoint  = local.rwx_filestore_endpoint
      rwx_filestore_path      = local.rwx_filestore_path
      jump_rwx_filestore_path = var.jump_rwx_filestore_path
      vm_admin                = var.jump_vm_admin
      }
    )
  }
  depends_on = [aws_efs_file_system.efs-fs, aws_efs_mount_target.efs-mt, module.nfs]
}

# Jump BOX
module "jump" {
  count              = var.create_jump_vm ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-jump"
  tags               = local.tags
  subnet_id          = local.jump_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = var.create_jump_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  vm_type               = var.jump_vm_type
  vm_admin              = var.jump_vm_admin
  ssh_public_key        = local.ssh_public_key
  enable_ebs_encryption = var.enable_ebs_encryption

  cloud_init = data.cloudinit_config.jump[0].rendered

  depends_on = [module.nfs]

}

# Defining the cloud-config to use
data "cloudinit_config" "nfs" {
  count = var.storage_type == "standard" ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/files/cloud-init/nfs/cloud-config", {
      vm_admin             = var.nfs_vm_admin
      public_subnet_cidrs  = join(" ", module.vpc.public_subnet_cidrs)
      private_subnet_cidrs = join(" ", module.vpc.private_subnet_cidrs)
      }
    )
  }
}

# NFS Server VM
module "nfs" {
  count              = var.storage_type == "standard" ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-nfs-server"
  tags               = local.tags
  subnet_id          = local.nfs_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = var.create_nfs_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  data_disk_count             = 4
  data_disk_type              = var.nfs_raid_disk_type
  data_disk_size              = var.nfs_raid_disk_size
  data_disk_iops              = var.nfs_raid_disk_iops
  data_disk_availability_zone = local.nfs_vm_subnet_az

  vm_type               = var.nfs_vm_type
  vm_admin              = var.nfs_vm_admin
  ssh_public_key        = local.ssh_public_key
  enable_ebs_encryption = var.enable_ebs_encryption

  cloud_init = data.cloudinit_config.nfs[0].rendered
}
