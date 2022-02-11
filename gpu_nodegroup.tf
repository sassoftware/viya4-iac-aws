/*
 * This file creates a AWS EKS Node Group based on Launch Template.
 * 
 */
resource "aws_key_pair" "gpu_ng" {
  key_name   = "${var.prefix}-gpu-nodes-key"
  public_key = local.ssh_public_key
}

/*
 * When nodes are created using custom Launch Template AWS requires Cluster info passed as args to bootstrap script
 */
data "template_file" "gpu_ng" {
  count = length(local.gpu_node_pool)
  template = file("${path.module}/files/templates/lt_userdata.tmpl")
  vars = {
    b64_cluster_ca = local.kubeconfig_ca_cert
    api_server_url = module.eks.cluster_endpoint
    cluster_name = local.cluster_name
    ami_id = var.gpu_image_id
    nodegroup_name = local.gpu_node_pool[count.index].name
  }
}
resource "aws_launch_template" "gpu_ng" {
  count = length(local.gpu_node_pool)

  name_prefix = "${var.prefix}-launch-template-${count.index}"
  image_id = var.gpu_image_id
  instance_type = local.gpu_node_pool[count.index].instance_type
  key_name = aws_key_pair.gpu_ng.key_name

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = local.gpu_node_pool[count.index].root_volume_size
      volume_type = local.gpu_node_pool[count.index].root_volume_type
      iops = local.gpu_node_pool[count.index].root_iops
    }
  }

  metadata_options {
    http_endpoint = local.gpu_node_pool[count.index].metadata_http_endpoint
    http_tokens = local.gpu_node_pool[count.index].metadata_http_tokens
    http_put_response_hop_limit = local.gpu_node_pool[count.index].metadata_http_put_response_hop_limit
  }

  vpc_security_group_ids = [ local.workers_security_group_id ]

  # NOTE: with custom launch template user_data is required for nodes to join EKS cluster
  # Reference - https://docs.aws.amazon.com/eks/latest/userguide/launch-templates.html#launch-template-user-data
  user_data = local.gpu_node_pool[count.index].additional_userdata != "" ? base64encode(local.gpu_node_pool[count.index].additional_userdata) : base64encode(data.template_file.gpu_ng[count.index].rendered)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eks_node_group" "gpu_ng" {

  count = length(local.gpu_node_pool)

  cluster_name    = local.cluster_name
  node_group_name = local.gpu_node_pool[count.index].name
  node_role_arn   = module.eks.worker_iam_role_arn
  subnet_ids      = module.vpc.private_subnets
  # version         = var.kubernetes_version
  tags = var.tags

  launch_template {
    id = aws_launch_template.gpu_ng[count.index].id
    version = aws_launch_template.gpu_ng[count.index].latest_version
  }
  scaling_config {
    desired_size = local.gpu_node_pool[count.index].asg_desired_capacity
    max_size     = local.gpu_node_pool[count.index].asg_max_size
    min_size     = local.gpu_node_pool[count.index].asg_min_size
  }

  labels = tomap (local.gpu_node_pool[count.index].labels)

  dynamic "taint" {
    for_each = tolist(local.gpu_node_pool[count.index].taints)
    content {
      key    = "${element(split("=", taint.value),0)}"
      value  = "${element(split(":", element( split("=", taint.value), 1)), 0 )}"
      effect = length(regexall( ":No", taint.value)) > 0  ? upper(replace( 
                                                                    element( split( ":", element( split( "=", taint.value), 1)), 1 ),"No", "NO_")
                                                            ) : upper(replace( 
                                                                    element( split( ":", element( split( "=", taint.value), 1)), 1), "No", "_NO_")
                                                            )
    }
  }
}
