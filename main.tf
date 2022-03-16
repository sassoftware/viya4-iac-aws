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

# EKS Setup - https://github.com/terraform-aws-modules/terraform-aws-eks
module "eks" {
  source                                         = "terraform-aws-modules/eks/aws"
  version                                        = "18.7.1"
  cluster_name                                   = local.cluster_name
  cluster_version                                = var.kubernetes_version
  cluster_endpoint_private_access                = true
  cluster_endpoint_public_access                 = true # local.is_standard
  cluster_endpoint_public_access_cidrs           = local.cluster_endpoint_public_access_cidrs
  
  subnet_ids                                     = module.vpc.private_subnets
  vpc_id                                         = module.vpc.vpc_id
  tags                                           = var.tags
  enable_irsa                                    = var.autoscaling_enabled
  ################################################################################
  # Cluster Security Group
  ################################################################################
  create_cluster_security_group                  = true                            # v17: cluster_create_security_group
  # cluster_security_group_id                      = local.cluster_security_group_id
  # cluster_security_group_name                    = 

  # Extend cluster security group rules
  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }
  
  ################################################################################
  # Node Security Group
  ################################################################################
  create_node_security_group                     = false ## DEBUGGING with true                            # worker_create_security_group   
  # node_security_group_name                       = "upgrd-sg"                
  node_security_group_id                         = local.workers_security_group_id  # worker_security_group_id  

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  # BYO IAM policy(!)
  create_iam_role                                = var.cluster_iam_role_name == null ? true : false   # v17: manage_cluster_iam_resources
  iam_role_name                                  = var.cluster_iam_role_name        # v17: cluster_iam_role_name
  iam_role_additional_policies = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ]

  create_cloudwatch_log_group                    = false

  ## -- NO LONGER SUPPORTED
  # cluster_create_endpoint_private_access_sg_rule = true # NOTE: If true cluster_endpoint_private_access_cidrs must always be set
  # cluster_endpoint_private_access_cidrs          = local.cluster_endpoint_private_access_cidrs
  # cluster_endpoint_private_access_sg             = [local.security_group_id]
  # write_kubeconfig                               = false
  # manage_worker_iam_resources                    = var.workers_iam_role_name == null ? true : false
  # workers_role_name                              = var.workers_iam_role_name 
  # 
  # manage_worker_iam_resources                    = var.workers_iam_role_name == null ? true : false
  # workers_role_name                              = var.workers_iam_role_name
  # worker_create_security_group                   = false
  # worker_security_group_id                       = local.workers_security_group_id
  # 
  ## -- NO LONGER SUPPORTED


  ## -- TBD
  # cluster_additional_security_group_ids = [] # "List of additional, externally created security group IDs to attach to the cluster control plane"
  # cluster_tags = {}  # A map of additional tags to add to the cluste
  # cluster_timeouts = {}
  ## -- TBD

  eks_managed_node_group_defaults = {
    # create_launch_template    = false
    create_security_group = false ## DEBUGGING with true
  #   # security_group_name            = "mnm-eks-managed-node-group"
  #   # security_group_use_name_prefix = false
  #   # security_group_description     = "MNM EKS managed node group complete example security group"
    vpc_security_group_ids          = [local.workers_security_group_id]
  }
  
  eks_managed_node_groups = local.worker_groups  
  
  /*
  eks_managed_node_groups {

    # Default node group - as provisioned by the module defaults
    # default_node_group = {}
  
    complete = {
      name  = "${var.prefix}-stateless-ng"
      use_name_prefix = false
      ## TODO: try with e.g., subnet_ids = module.vpc.public_subnets
      subnet_ids  = module.vpc.private_subnets

      min_size     = 1
      max_size     = 3
      desired_size = 1

      # ami_id               = data.aws_ami.eks_default.id
      bootstrap_extra_args = "--kubelet-extra-args '--max-pods=110'"

      capacity_type        = "SPOT"
      disk_size            = 256
      force_update_version = true
      instance_type = ["m6i.large"]
      labels = {
        GithubRepo = "terraform-aws-eks"
        GithubOrg  = "terraform-aws-modules"
      }

      taints = [
        {
          key    = "dedicated"
          value  = "gpuGroup"
          effect = "NO_SCHEDULE"
        }
      ]

      # launch_template_name            = "${var.prefix}-lt"
      # launch_template_use_name_prefix = true
      # launch_template_description     = "Self managed node group example launch template"

      ebs_optimized          = true
      # vpc_security_group_ids = [aws_security_group.additional.id]
      disable_api_termination = false
      enable_monitoring      = false

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 75
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = true
            # kms_key_id            = aws_kms_key.ebs.arn
            delete_on_termination = true
          }
        }
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
        instance_metadata_tags      = "disabled"
      }

      create_iam_role          = true # var.cluster_iam_role_name == null ? true : false   # manage_cluster_iam_resources
      iam_role_name            = "eks-managed-node-group-complete-example"
      iam_role_use_name_prefix = false
      iam_role_description     = "EKS managed node group complete example role"
      iam_role_tags = {
        Purpose = "Protector of the kubelet"
      }
      iam_role_additional_policies = [
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]

      create_security_group          = true
      security_group_name            = "${var.prefix}-stateless-ng-sg"
      security_group_use_name_prefix = false
      security_group_description     = "EKS managed node group complete example security group"
      security_group_rules = {
        phoneHome = {
          description                   = "Hello cluster"
          protocol                      = "udp"
          from_port                     = 53
          to_port                       = 53
          type                          = "egress"
          source_cluster_security_group = true # bit of reflection lookup
        }
      }
      security_group_tags = {
        Purpose = "Protector of the kubelet"
      }

      tags = {
        ExtraTag = "${var.prefix}-Viya Stateless NG Tag"
      }
    }
  }
  */
}

resource "aws_security_group" "additional" {
  name_prefix = "${local.cluster_name}-additional-sg"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
  tags = var.tags
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

  vpc_security_group_ids = [local.security_group_id, local.workers_security_group_id]

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
