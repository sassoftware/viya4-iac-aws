## AWS-EKS
#
# Terraform Registry : https://registry.terraform.io/namespaces/terraform-aws-modules
# GitHub Repository  : https://github.com/terraform-aws-modules
#

provider "aws" {
  region                  = var.location
  profile                 = var.aws_profile
  shared_credentials_file = var.aws_shared_credentials_file
  access_key              = var.aws_access_key_id
  secret_key              = var.aws_secret_access_key
  token                   = var.aws_session_token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "terraform" {}

data "external" "git_hash" {
  program = ["files/tools/iac_git_info.sh"]
}

data "external" "iac_tooling_version" {
  program = ["files/tools/iac_tooling_version.sh"]
}

resource "kubernetes_config_map" "sas_iac_buildinfo" {
  metadata {
    name      = "sas-iac-buildinfo"
    namespace = "kube-system"
  }

  data = {
    git-hash    = lookup(data.external.git_hash.result, "git-hash")
    timestamp   = chomp(timestamp())
    iac-tooling = var.iac_tooling
    terraform   = <<EOT
version: ${lookup(data.external.iac_tooling_version.result, "terraform_version")}
revision: ${lookup(data.external.iac_tooling_version.result, "terraform_revision")}
provider-selections: ${lookup(data.external.iac_tooling_version.result, "provider_selections")}
outdated: ${lookup(data.external.iac_tooling_version.result, "terraform_outdated")}
EOT
  }
}

# EKS Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(local.kubeconfig_ca_cert)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

module "vpc" {
  source = "./modules/aws_vpc"

  name                = var.prefix
  vpc_id              = var.vpc_id
  region              = var.location
  security_group_id   = local.security_group_id
  cidr                = var.vpc_cidr
  azs                 = data.aws_availability_zones.available.names
  vpc_private_enabled = local.is_private
  existing_subnet_ids = var.subnet_ids
  subnets             = var.subnets
  existing_nat_id     = var.nat_id

  tags = var.tags
  public_subnet_tags  = merge(var.tags, { "kubernetes.io/role/elb" = "1" }, { "kubernetes.io/cluster/${local.cluster_name}" = "shared" })
  private_subnet_tags = merge(var.tags, { "kubernetes.io/role/internal-elb" = "1" }, { "kubernetes.io/cluster/${local.cluster_name}" = "shared" })
}

data aws_security_group sg {
  count = var.security_group_id == null ? 0 : 1
  id = var.security_group_id
}

# Security Groups - https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "sg" {
  count = var.security_group_id == null ? 1 : 0
  name   = "${var.prefix}-sg"
  vpc_id = module.vpc.vpc_id

  egress {
    description = "Allow all outbound traffic."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = merge(var.tags, tomap({ Name: "${var.prefix}-sg" }))
}

# EFS File System - https://www.terraform.io/docs/providers/aws/r/efs_file_system.html
resource "aws_efs_file_system" "efs-fs" {
  count            = var.storage_type == "ha" ? 1 : 0
  creation_token   = "${var.prefix}-efs"
  performance_mode = var.efs_performance_mode
  tags             = merge(var.tags, tomap({ Name: "${var.prefix}-efs" }))
}

# EFS Mount Target - https://www.terraform.io/docs/providers/aws/r/efs_mount_target.html
resource "aws_efs_mount_target" "efs-mt" {
  # NOTE - Testing. use num_azs = 2
  count           = var.storage_type == "ha" ? length(module.vpc.private_subnets) : 0
  file_system_id  = aws_efs_file_system.efs-fs.0.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [local.security_group_id]
}

# Processing the cloud-init/jump/cloud-config template file
data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/files/cloud-init/jump/cloud-config")
  vars = {
    rwx_filestore_endpoint  = var.storage_type == "ha" ? aws_efs_file_system.efs-fs.0.dns_name : module.nfs.private_ip_address
    rwx_filestore_path      = var.storage_type == "ha" ? "/" : "/export"
    jump_rwx_filestore_path = var.jump_rwx_filestore_path
    vm_admin                = var.jump_vm_admin
  }

  depends_on = [aws_efs_file_system.efs-fs, aws_efs_mount_target.efs-mt, module.nfs]
}

# Defining the cloud-config to use
data "template_cloudinit_config" "jump" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = data.template_file.jump-cloudconfig.rendered
  }
}

# Jump BOX
module "jump" {
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-jump"
  tags               = var.tags
  subnet_id          = local.jump_vm_subnet
  security_group_ids = [local.security_group_id]
  create_public_ip   = local.create_jump_public_ip

  os_disk_type                  = var.os_disk_type
  os_disk_size                  = var.os_disk_size
  os_disk_delete_on_termination = var.os_disk_delete_on_termination
  os_disk_iops                  = var.os_disk_iops

  create_vm      = var.create_jump_vm
  vm_type        = var.jump_vm_type
  vm_admin       = var.jump_vm_admin
  ssh_public_key = file(var.ssh_public_key)

  cloud_init = data.template_cloudinit_config.jump.rendered

  depends_on = [module.nfs, aws_security_group_rule.all]

}

resource "aws_security_group_rule" "vms" {
  count             = ((var.storage_type == "standard" && local.create_nfs_public_ip) || var.create_jump_vm) && length(local.vm_public_access_cidrs) > 0 ? 1 : 0
  type              = "ingress"
  description       = "Allow SSH from source"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = local.vm_public_access_cidrs
  security_group_id = local.security_group_id
}

resource "aws_security_group_rule" "all" {
  type              = "ingress"
  description       = "Allow internal security group communication."
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  security_group_id = local.security_group_id
  self              = true
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
  source             = "./modules/aws_vm"
  name               = "${var.prefix}-nfs-server"
  tags               = var.tags
  subnet_id          = local.nfs_vm_subnet
  security_group_ids = [local.security_group_id]
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

  create_vm      = var.storage_type == "standard" ? true : false
  vm_type        = var.nfs_vm_type
  vm_admin       = var.nfs_vm_admin
  ssh_public_key = file(var.ssh_public_key)

  cloud_init = var.storage_type == "standard" ? data.template_cloudinit_config.nfs.0.rendered : null
}

# EBS CSI driver IAM Policy for EKS worker nodes - https://registry.terraform.io/modules/terraform-aws-modules/iam
# module "iam_policy" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "4.1.0"

#   count = var.workers_iam_role_name == null ? 1 : 0

#   name        = "${var.prefix}_ebs_csi_policy"
#   description = "EBS CSI driver IAM Policy"

#   policy = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": [
#         "ec2:AttachVolume",
#         "ec2:CreateSnapshot",
#         "ec2:CreateTags",
#         "ec2:CreateVolume",
#         "ec2:DeleteSnapshot",
#         "ec2:DeleteTags",
#         "ec2:DeleteVolume",
#         "ec2:DescribeInstances",
#         "ec2:DescribeSnapshots",
#         "ec2:DescribeTags",
#         "ec2:DescribeVolumes",
#         "ec2:DetachVolume",
#         "elasticfilesystem:DescribeFileSystems",
#         "iam:DeletePolicyVersion"
#       ],
#       "Effect": "Allow",
#       "Resource": "*"
#     }
#   ]
# }
# EOF
# }

# EKS Setup - https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source                                         = "terraform-aws-modules/eks/aws"
  version                                        = "17.1.0"
  cluster_name                                   = local.cluster_name
  cluster_version                                = var.kubernetes_version
  cluster_endpoint_private_access                = true
  cluster_create_endpoint_private_access_sg_rule = true # NOTE: If true cluster_endpoint_private_access_cidrs must always be set
  cluster_endpoint_private_access_sg             = [local.security_group_id]
  cluster_endpoint_private_access_cidrs          = local.cluster_endpoint_private_access_cidrs
  cluster_endpoint_public_access                 = local.is_standard
  cluster_endpoint_public_access_cidrs           = local.cluster_endpoint_public_access_cidrs
  write_kubeconfig                               = false
  subnets                                        = module.vpc.private_subnets
  vpc_id                                         = module.vpc.vpc_id
  tags                                           = var.tags
  enable_irsa                                    = var.autoscaling_enabled
  
  manage_worker_iam_resources                    = var.workers_iam_role_name == null ? true : false
  workers_role_name                              = var.workers_iam_role_name
  manage_cluster_iam_resources                   = var.cluster_iam_role_name == null ? true : false
  cluster_iam_role_name                          = var.cluster_iam_role_name

  workers_group_defaults = {
    tags                                 = var.autoscaling_enabled ? [ { key = "k8s.io/cluster-autoscaler/${local.cluster_name}", value = "owned", propagate_at_launch = true }, { key = "k8s.io/cluster-autoscaler/enabled", value = "true", propagate_at_launch = true} ] : null
    additional_security_group_ids        = [local.security_group_id]
    metadata_http_tokens                 = "required"
    metadata_http_put_response_hop_limit = 1
    bootstrap_extra_args                 = local.is_private ? "--apiserver-endpoint ${data.aws_eks_cluster.cluster.endpoint} --b64-cluster-ca" + base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data) : ""
    iam_instance_profile_name            = var.workers_iam_role_name
  }

  # Added to support EBS CSI driver
  # workers_additional_policies = [var.workers_iam_role_name == null ? module.iam_policy.0.arn : null]

  worker_groups = local.worker_groups
}

module "autoscaling" {
  source       = "./modules/aws_autoscaling"
  count        = var.autoscaling_enabled ? 1 : 0

  prefix       = var.prefix
  cluster_name = local.cluster_name
  tags         = var.tags
  oidc_url     = module.eks.cluster_oidc_issuer_url
}

module "kubeconfig" {
  source                   = "./modules/kubeconfig"
  prefix                   = var.prefix
  create_static_kubeconfig = var.create_static_kubeconfig
  path                     = local.kubeconfig_path
  namespace                = "kube-system"

  cluster_name             = local.cluster_name
  region                   = var.location
  endpoint                 = module.eks.cluster_endpoint
  ca_crt                   = local.kubeconfig_ca_cert

  depends_on = [ module.eks ]
}

# Database Setup - https://registry.terraform.io/modules/terraform-aws-modules/rds/aws/3.3.0
module "postgresql" {
  source  = "terraform-aws-modules/rds/aws"
  version = "3.3.0"

  for_each   = local.postgres_servers != null ? length(local.postgres_servers) != 0 ? local.postgres_servers : {} : {}

  identifier = lower("${var.prefix}-${each.key}-pgsql")

  engine            = "postgres"
  engine_version    = each.value.server_version
  instance_class    = each.value.instance_type
  allocated_storage = each.value.storage_size
  storage_encrypted = each.value.storage_encrypted

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = each.value.administrator_login
  password = each.value.administrator_password
  port     = each.value.server_port

  vpc_security_group_ids = [local.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = each.value.backup_retention_days

  tags = var.tags

  # DB subnet group - use public subnet if public access is requested
  publicly_accessible = length(local.postgres_public_access_cidrs) > 0 ? true : false
  subnet_ids          = length(local.postgres_public_access_cidrs) > 0 ? module.vpc.public_subnets : module.vpc.database_subnets

  # DB parameter group
  family = "postgres${each.value.server_version}"

  # DB option group
  major_engine_version = each.value.server_version

  # Database Deletion Protection
  deletion_protection = each.value.deletion_protection

  multi_az = each.value.multi_az

  parameters = each.value.ssl_enforcement_enabled ? concat(each.value.parameters, [{ "apply_method": "immediate", "name": "rds.force_ssl", "value": "1" }]) : concat(each.value.parameters, [{ "apply_method": "immediate", "name": "rds.force_ssl", "value": "0" }])
  options    = each.value.options

  # Flags for module to flag if postgres should be created or not.
  create_db_instance        = true
  create_db_subnet_group    = true
  create_db_parameter_group = true
  create_db_option_group    = true

}

resource "aws_security_group_rule" "postgres_internal" {
  for_each          = local.postgres_sgr_ports != null ? toset(local.postgres_sgr_ports) : toset([])
  type              = "ingress"
  description       = "Allow Postgres within network"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  self              = true
  security_group_id = local.security_group_id
}

resource "aws_security_group_rule" "postgres_external" {
  for_each          = length(local.postgres_public_access_cidrs) > 0 ? local.postgres_sgr_ports != null ? toset(local.postgres_sgr_ports) : toset([]) : toset([])
  type              = "ingress"
  description       = "Allow Postgres from source"
  from_port         = each.key
  to_port           = each.key
  protocol          = "tcp"
  cidr_blocks       = local.postgres_public_access_cidrs
  security_group_id = local.security_group_id
}

# Resource Groups - https://www.terraform.io/docs/providers/aws/r/resourcegroups_group.html
resource "aws_resourcegroups_group" "aws_rg" {
  name = "${var.prefix}-rg"

  resource_query {
    query = <<JSON
{
  "ResourceTypeFilters": [
    "AWS::AllSupported"
  ],
  "TagFilters": ${jsonencode([
    for key, values in var.tags : {
      "Key" : key,
      "Values" : [values]
    }
])}
}
JSON
}
}
