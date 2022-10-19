locals {
  rwx_filestore_endpoint = ( var.storage_type == "none"
                            ? null
                            : var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.dns_name : module.nfs.0.private_ip_address
                           )
  rwx_filestore_path = ( var.storage_type == "none"
                         ? null
                         : var.storage_type == "ha" ? "/" : "/export"
                       )
  fsx_filestore_endpoint = ( var.create_fsx_filestore ? aws_fsx_lustre_file_system.fsx-fs.0.dns_name : null )
  fsx_filestore_path = ( var.create_fsx_filestore ? "/" : null )
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

# FSx File System https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/fsx_lustre_file_system
resource "aws_fsx_lustre_file_system" "fsx-fs" {
  count            = var.create_fsx_filestore ? 1 : 0
  storage_capacity            = var.fsx_storage_capacity
  deployment_type             = var.fsx_deployment_type
  per_unit_storage_throughput = var.fsx_per_unit_storage_throughput
  # import_path      = "s3://${aws_s3_bucket.example.bucket}"
  subnet_ids = [module.vpc.private_subnets[0]]
  tags       = merge(var.tags, { "Name" : "${var.prefix}-fsx" })
}

# The template provider is deprecated
# https://registry.terraform.io/providers/hashicorp/template/latest/docs#deprecation
# Defining the cloud-config to use
data "template_cloudinit_config" "jump" {
  count         = var.create_jump_vm ? 1 : 0
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/files/cloud-init/jump/cloud-config",
      {
        mount_nfs = ( var.storage_type == "none"
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
        mount_fsx = ( var.create_fsx_filestore
                    ? jsonencode(
                        ["${local.rwx_filestore_endpoint}:${local.rwx_filestore_path}",
                          "${var.jump_fsx_filestore_path}",
                          "lustre",
                          "rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport,noatime,flock,_netdev",
                          "0",
                          "0"
                      ])
                    : null
                    )

        rwx_filestore_endpoint  = local.rwx_filestore_endpoint
        rwx_filestore_path      = local.rwx_filestore_path
        jump_rwx_filestore_path = var.jump_rwx_filestore_path
        fsx_filestore_endpoint  = local.fsx_filestore_endpoint
        fsx_filestore_path      = local.fsx_filestore_path
        jump_fsx_filestore_path = var.jump_fsx_filestore_path
        vm_admin                = var.jump_vm_admin
        kubeconfig_file_content = jsonencode(module.kubeconfig.kube_config)
        kubeconfig_filename     = local.kubeconfig_filename
      }
    )
  }
  depends_on = [module.kubeconfig, aws_efs_file_system.efs-fs, aws_efs_mount_target.efs-mt, module.nfs, aws_fsx_lustre_file_system.fsx-fs]
}

# Jump BOX
module "jump" {
  count              = var.create_jump_vm ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-jump"
  tags               = var.tags
  subnet_id          = local.jump_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = var.create_jump_public_ip
  iam_instance_profile = var.instance_profile_jump_vm ? aws_iam_instance_profile.jump_vm_profile.0.name : null

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = contains(["gp2", "gp3", "io1", "io2"], var.os_disk_type) ? var.os_disk_iops : null
  os_disk_throughput            = var.os_disk_type == "gp3" ? var.os_disk_throughput : null

  vm_type        = var.jump_vm_type
  ebs_optimized  = var.jump_vm_ebs_optimized
  vm_admin       = var.jump_vm_admin
  ssh_public_key = local.ssh_public_key

  cloud_init = data.template_cloudinit_config.jump.0.rendered

  depends_on = [aws_efs_file_system.efs-fs, aws_efs_mount_target.efs-mt, aws_fsx_lustre_file_system.fsx-fs, module.nfs]
}

# Defining the cloud-config to use
data "template_cloudinit_config" "nfs" {
  count = var.storage_type == "standard" ? 1 : 0

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/files/cloud-init/nfs/cloud-config",
      {
        vm_admin        = var.nfs_vm_admin
        public_subnet_cidrs  = join(" ", module.vpc.public_subnet_cidrs)
        private_subnet_cidrs = join(" ", module.vpc.private_subnet_cidrs)
      }
    )
  }
  depends_on = [
    module.vpc
  ]
}

# NFS Server VM
module "nfs" {
  count              = var.storage_type == "standard" ? 1 : 0
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-nfs-server"
  tags               = var.tags
  subnet_id          = local.nfs_vm_subnet
  security_group_ids = [local.security_group_id, local.workers_security_group_id]
  create_public_ip   = var.create_nfs_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = contains(["gp2","gp3", "io1", "io2"], var.os_disk_type) ? var.os_disk_iops : null
  os_disk_throughput            = var.os_disk_type == "gp3" ? var.os_disk_throughput : null

  data_disk_count             = 4
  data_disk_type              = var.nfs_raid_disk_type
  data_disk_size              = var.nfs_raid_disk_size
  data_disk_iops              = contains(["gp2", "gp3", "io1", "io2"], var.nfs_raid_disk_type) ? var.nfs_raid_disk_iops : null
  data_disk_throughput        = var.nfs_raid_disk_type == "gp3" ? var.nfs_raid_disk_throughput : null
  data_disk_availability_zone = local.nfs_vm_subnet_az

  vm_type        = var.nfs_vm_type
  ebs_optimized  = var.nfs_vm_ebs_optimized
  vm_admin       = var.nfs_vm_admin
  ssh_public_key = local.ssh_public_key

  cloud_init = data.template_cloudinit_config.nfs.0.rendered
}

resource "aws_iam_policy" "eks_management_instance_profile_policy" {
  count       = var.create_jump_vm && var.instance_profile_jump_vm ? 1 : 0
  name        = "eks_management_instance_profile_policy"
  description = format("Instance profile policy to manage EKS cluster")
  path        = "/"

  #tfsec:ignore:AWS099
  policy = file("${path.module}/eks_management_instance_profile_policy.json")
  tags       = merge(var.tags, { "Name" : "${var.prefix}-jump-instance-profile-policy" })
}

resource "aws_iam_role" "jump_vm_instance_profile_role" {
  count       = var.create_jump_vm && var.instance_profile_jump_vm ? 1 : 0
  name = "jump_vm_instance_profile_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags       = merge(var.tags, { "Name" : "${var.prefix}-jump-instance-profile-role" })
}


resource "aws_iam_policy_attachment" "jump_vm_policy_attachment" {
  count       = var.create_jump_vm && var.instance_profile_jump_vm ? 1 : 0
  name       = "jump_vm_policy_attachment"
  roles      = [aws_iam_role.jump_vm_instance_profile_role.0.name]
  policy_arn = aws_iam_policy.eks_management_instance_profile_policy.0.arn
}

resource "aws_iam_instance_profile" "jump_vm_profile" {
  count       = var.create_jump_vm && var.instance_profile_jump_vm ? 1 : 0
  name = "jump_vm_profile"
  role = aws_iam_role.jump_vm_instance_profile_role.0.name
}