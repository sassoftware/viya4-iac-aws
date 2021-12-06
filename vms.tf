locals {
  rwx_filestore_endpoint  = ( var.storage_type == "none"
                              ? "" 
                              : var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.dns_name : module.nfs.0.private_ip_address
                            )
  rwx_filestore_path      = ( var.storage_type == "none"
                              ? ""
                              : var.storage_type == "ha" ? "/" : "/export"
                            )
}

# EFS File System - https://www.terraform.io/docs/providers/aws/r/efs_file_system.html
resource "aws_efs_file_system" "efs-fs" {
  count            = var.storage_type == "ha" ? 1 : 0
  creation_token   = "${var.prefix}-efs"
  performance_mode = var.efs_performance_mode
  tags             = merge(var.tags, { "Name": "${var.prefix}-efs" })
}

# EFS Mount Target - https://www.terraform.io/docs/providers/aws/r/efs_mount_target.html
resource "aws_efs_mount_target" "efs-mt" {
  # NOTE - Testing. use num_azs = 2
  count           = var.storage_type == "ha" ? length(module.vpc.private_subnets) : 0
  file_system_id  = aws_efs_file_system.efs-fs.0.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [local.workers_security_group_id]
}


# Processing the cloud-init/jump/cloud-config template file
data "template_file" "jump-cloudconfig" {
  count    = var.create_jump_vm ? 1 : 0
  template = file("${path.module}/files/cloud-init/jump/cloud-config")
  vars     = {
    mounts = ( var.storage_type == "none"
               ? "[]"
               : jsonencode(
                  [ "${local.rwx_filestore_endpoint}:${local.rwx_filestore_path}",
                    "${var.jump_rwx_filestore_path}",
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
  depends_on = [aws_efs_file_system.efs-fs, aws_efs_mount_target.efs-mt, module.nfs]
}

# Defining the cloud-config to use
data "template_cloudinit_config" "jump" {
  count         = var.create_jump_vm ? 1 : 0
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.jump-cloudconfig.0.rendered
  }
}

# Jump BOX
module "jump" {
  count              = var.create_jump_vm ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-jump"
  tags               = var.tags
  subnet_id          = local.jump_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = local.create_jump_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  vm_type        = var.jump_vm_type
  vm_admin       = var.jump_vm_admin
  ssh_public_key = local.ssh_public_key

  cloud_init = data.template_cloudinit_config.jump.0.rendered

  depends_on = [module.nfs]

}

data "template_file" "nfs-cloudconfig" {
  template = file("${path.module}/files/cloud-init/nfs/cloud-config")
  count    = var.storage_type == "standard" ? 1 : 0

  vars = {
    vm_admin        = var.nfs_vm_admin
    public_subnet_cidrs  = join(" ", module.vpc.public_subnet_cidrs)
    private_subnet_cidrs = join(" ", module.vpc.private_subnet_cidrs)
  }

}

# Defining the cloud-config to use
data "template_cloudinit_config" "nfs" {
  count = var.storage_type == "standard" ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.nfs-cloudconfig.0.rendered
  }
}

# NFS Server VM
module "nfs" {
  count              = var.storage_type == "standard" ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-nfs-server"
  tags               = var.tags
  subnet_id          = local.nfs_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = local.create_nfs_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  data_disk_count             = 4
  data_disk_type              = var.nfs_raid_disk_type
  data_disk_size              = var.nfs_raid_disk_size
  data_disk_iops              = var.nfs_raid_disk_iops
  data_disk_availability_zone = local.nfs_vm_subnet_az

  vm_type        = var.nfs_vm_type
  vm_admin       = var.nfs_vm_admin
  ssh_public_key = local.ssh_public_key

  cloud_init = data.template_cloudinit_config.nfs.0.rendered
}

