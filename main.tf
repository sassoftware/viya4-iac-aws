## AWS-EKS
#
# Terraform Registry : https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/12.1.0
# GitHub Repository  : https://github.com/terraform-aws-modules
#
terraform {
  required_version = ">= 0.13.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.9.0"
    }
  }
  
}

provider "aws" {
  region  = var.location
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_availability_zones" "available" {}

locals {
   cluster_name = "${var.prefix}-eks"
}

# EKS Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}

# VPC Setup - https://github.com/terraform-aws-modules/terraform-aws-vpc
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.55.0"

  name                 = "${var.prefix}-vpc"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  # database_subnets     = [module.vpc.private_subnets.2, module.vpc.private_subnets.3]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = var.tags
  public_subnet_tags = merge( var.tags, {"kubernetes.io/role/elb"="1"}, {"kubernetes.io/cluster/${var.prefix}-eks"="shared"} )
  private_subnet_tags = merge( var.tags, {"kubernetes.io/role/internal-elb"="1"}, {"kubernetes.io/cluster/${var.prefix}-eks"="shared"} )
}

# Associate private subnets with the private routing table.
resource "aws_route_table_association" "private" {
  count = length(module.vpc.private_subnets)

  subnet_id      = module.vpc.private_subnets[count.index]
  route_table_id = module.vpc.private_route_table_ids[0]
}

# Associate public subnets with the public routing table.
resource "aws_route_table_association" "public" {
  count = length(module.vpc.public_subnets)

  subnet_id      = module.vpc.public_subnets[count.index]
  route_table_id = module.vpc.public_route_table_ids[0]
}

# Security Groups - https://www.terraform.io/docs/providers/aws/r/security_group.html
resource "aws_security_group" "sg" {
  name = "${var.prefix}-sg"
  vpc_id = module.vpc.vpc_id

  dynamic "ingress" {
    for_each = var.sg_ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # For pod access on the internal network
  ingress {
    description = "Allow Postgres"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = true
  }

  dynamic "egress" {
    for_each = var.sg_egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(var.tags, map("Name", "${var.prefix}-sg"))

}

resource "aws_security_group_rule" "nfs" {
  description       = "Allow NFS (TCP)"
  type              = "ingress"
  from_port         = 2049
  to_port           = 2049
  protocol          = "TCP"
  security_group_id = module.vpc.default_security_group_id
  source_security_group_id = aws_security_group.sg.id
}
 
# EFS File System - https://www.terraform.io/docs/providers/aws/r/efs_file_system.html
resource "aws_efs_file_system" "efs-fs" {
  creation_token = "${var.prefix}-efs"
  tags           = merge(var.tags, map("Name", "${var.prefix}-efs"))
}

# EFS Mount Target - https://www.terraform.io/docs/providers/aws/r/efs_mount_target.html
resource "aws_efs_mount_target" "efs-mt" {
  count          = length(module.vpc.private_subnets)
  file_system_id = aws_efs_file_system.efs-fs.id
  subnet_id      = element(module.vpc.private_subnets, count.index)
}

# Processing the cloud-init/jump/cloud-config template file
data "template_file" "jump-cloudconfig" {
  template = file("${path.module}/cloud-init/jump/cloud-config")
  vars = {
    rwx_filestore_endpoint = aws_efs_file_system.efs-fs.dns_name
    rwx_filestore_path     = "/"
  }

  depends_on = [aws_efs_file_system.efs-fs,aws_efs_mount_target.efs-mt]
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
  source = "./modules/aws_vm"
  name = "${var.prefix}-jump"
  tags = var.tags
  subnet_id = module.vpc.public_subnets[0] // gw subnet
  security_group_ids = [aws_security_group.sg.id]

  os_disk_type                    = var.os_disk_type
  os_disk_size                    = var.os_disk_size
  os_disk_delete_on_termination   = var.os_disk_delete_on_termination
  os_disk_iops                    = var.os_disk_iops

  create_vm = var.create_jump_vm

  cloud_init                      = data.template_cloudinit_config.jump.rendered

}

# EBS CSI driver IAM Policy for EKS worker nodes - https://registry.terraform.io/modules/terraform-aws-modules/iam
module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 2.0"

  name        = "${var.prefix}_ebs_csi_policy"
  description = "EBS CSI driver IAM Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:AttachVolume",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteSnapshot",
        "ec2:DeleteTags",
        "ec2:DeleteVolume",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "elasticfilesystem:DescribeFileSystems",
        "iam:DeletePolicyVersion"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# EKS Setup - https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source                                = "terraform-aws-modules/eks/aws"
  cluster_name                          = local.cluster_name
  cluster_version                       = var.kubernetes_version
  cluster_endpoint_private_access       = true
  cluster_endpoint_private_access_cidrs = [var.vpc_cidr]
  cluster_endpoint_public_access        = true
  cluster_endpoint_public_access_cidrs  = var.cluster_endpoint_public_access_cidrs
  config_output_path                    = "./${var.prefix}-eks-kubeconfig.conf"
  kubeconfig_name                       = "${var.prefix}-eks"
  subnets                               = concat( [module.vpc.private_subnets.0, module.vpc.private_subnets.1] )
  vpc_id                                = module.vpc.vpc_id
  tags                                  = var.tags

  workers_group_defaults = {
    # tags = var.tags
    additional_security_group_ids = [aws_security_group.sg.id]
  }

  # Added to support EBS CSI driver
  workers_additional_policies = [module.iam_policy.arn]

  worker_groups = [
    # Default
    {
      name                  = "default"
      instance_type         = var.default_nodepool_vm_type
      asg_desired_capacity  = var.default_nodepool_initial_node_count
      asg_max_size          = var.default_nodepool_max_nodes
      asg_min_size          = var.default_nodepool_min_nodes
      root_volume_size      = var.default_nodepool_os_disk_size
      root_volume_type      = var.default_nodepool_os_disk_type
      kubelet_extra_args    = "--node-labels=${join("," , var.default_nodepool_labels )} --register-with-taints=${join("," , var.default_nodepool_taints )}"

    },
    # CAS
    {
      name                  = "cas"
      instance_type         = var.cas_nodepool_vm_type
      asg_desired_capacity  = (var.create_cas_nodepool ? var.cas_nodepool_initial_node_count : 0)
      asg_max_size          = (var.create_cas_nodepool ? var.cas_nodepool_max_nodes : 0)
      asg_min_size          = (var.create_cas_nodepool ? var.cas_nodepool_min_nodes : 0)
      root_volume_size      = var.cas_nodepool_os_disk_size
      root_volume_type      = var.cas_nodepool_os_disk_type
      kubelet_extra_args    = "--node-labels=${join("," , var.cas_nodepool_labels )} --register-with-taints=${join("," , var.cas_nodepool_taints )}"
    },
    # Compute
    {
      name                  = "compute"
      instance_type         = var.compute_nodepool_vm_type
      asg_desired_capacity  = (var.create_compute_nodepool ? var.compute_nodepool_initial_node_count : 0)
      asg_max_size          = (var.create_compute_nodepool ? var.compute_nodepool_max_nodes : 0)
      asg_min_size          = (var.create_compute_nodepool ? var.compute_nodepool_min_nodes : 0)
      root_volume_size      = var.compute_nodepool_os_disk_size
      root_volume_type      = var.compute_nodepool_os_disk_type
      kubelet_extra_args    = "--node-labels=${join("," , var.compute_nodepool_labels )} --register-with-taints=${join("," , var.compute_nodepool_taints )}"
    },
    # stateless
    {
      name                  = "stateless"
      instance_type         = var.stateless_nodepool_vm_type
      asg_desired_capacity  = (var.create_stateless_nodepool ? var.stateless_nodepool_initial_node_count : 0)
      asg_max_size          = (var.create_stateless_nodepool ? var.stateless_nodepool_max_nodes : 0)
      asg_min_size          = (var.create_stateless_nodepool ? var.stateless_nodepool_min_nodes : 0)
      root_volume_size      = var.stateless_nodepool_os_disk_size
      root_volume_type      = var.stateless_nodepool_os_disk_type
      kubelet_extra_args    = "--node-labels=${join("," , var.stateless_nodepool_labels )} --register-with-taints=${join("," , var.stateless_nodepool_taints )}"
    },  
    # stateful
    {
      name                  = "stateful"
      instance_type         = var.stateful_nodepool_vm_type
      asg_desired_capacity  = (var.create_stateful_nodepool ? var.stateful_nodepool_initial_node_count : 0)
      asg_max_size          = (var.create_stateful_nodepool ? var.stateful_nodepool_max_nodes : 0)
      asg_min_size          = (var.create_stateful_nodepool ? var.stateful_nodepool_min_nodes : 0)
      root_volume_size      = var.stateful_nodepool_os_disk_size
      root_volume_type      = var.stateful_nodepool_os_disk_type
      kubelet_extra_args    = "--node-labels=${join("," , var.stateful_nodepool_labels )} --register-with-taints=${join("," , var.stateful_nodepool_taints )}"
    }
  ]
}

# Database Setup - https://github.com/terraform-aws-modules/terraform-aws-rds
module "db" {
  source = "terraform-aws-modules/rds/aws"
  version = "~> 2.18.0"

  identifier = (var.postgres_server_name == "" ? "${var.prefix}db" : var.postgres_server_name)

  engine            = "postgres"
  engine_version    = var.postgres_server_version
  instance_class    = var.postgres_instance_type # sku_name
  allocated_storage = var.postgres_storage_size
  storage_encrypted = var.postgres_storage_encrypted

  # kms_key_id        = "arm:aws:kms:<region>:<account id>:key/<kms key id>"
  name = var.postgres_db_name

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  username = var.postgres_postgres_administrator_login
  password = var.postgres_administrator_password
  port     = var.postgres_server_port

  vpc_security_group_ids = [aws_security_group.sg.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  # disable backups to create DB faster
  backup_retention_period = var.postgres_backup_retention_days

  tags = var.tags

  # enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  # DB subnet group
  subnet_ids = [module.vpc.private_subnets[2],module.vpc.private_subnets[3]]

  # DB parameter group
  family = "postgres${var.postgres_server_version}"

  # DB option group
  major_engine_version = var.postgres_server_version

  # Snapshot name upon DB deletion
  final_snapshot_identifier = (var.postgres_server_name == "" ? var.prefix : var.postgres_server_name)

  # Database Deletion Protection
  deletion_protection = var.postgres_deletion_protection
  
  multi_az = var.postgress_multi_az

  parameters = var.postgres_parameters
  options = var.postgres_options

  # Flags for module to flag if postgres should be created or not.
  create_db_instance        = var.create_postgres
  create_db_subnet_group    = var.create_postgres
  create_db_parameter_group = var.create_postgres
  create_db_option_group    = var.create_postgres

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
    for key,values in var.tags : {
      "Key": key,
      "Values": [values]
    }
  ])}
}
JSON
  }
}
