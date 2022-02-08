
resource "aws_key_pair" "gpu_ng" {
  key_name   = "${var.prefix}-gpu-nodes-key"
  public_key = local.ssh_public_key
}

resource "aws_launch_template" "gpu_ng" {
  count = length(local.gpu_node_pool)

  name_prefix = "${var.prefix}-launch-template-${count.index}"
  image_id = var.gpu_image_id
  instance_type = local.gpu_node_pool[count.index].instance_type
  key_name = aws_key_pair.gpu_ng.key_name
  

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = local.gpu_node_pool[count.index].root_volume_size
      volume_type = local.gpu_node_pool[count.index].root_volume_type
      iops = local.gpu_node_pool[count.index].root_iops
    }
  }

  # iam_instance_profile {
  #   arn = module.eks.worker_iam_role_arn
  # }

  metadata_options {
    http_endpoint = local.gpu_node_pool[count.index].metadata_http_endpoint
    http_tokens = local.gpu_node_pool[count.index].metadata_http_tokens
    http_put_response_hop_limit = local.gpu_node_pool[count.index].metadata_http_put_response_hop_limit
  }

  vpc_security_group_ids = [ local.workers_security_group_id ]

  user_data = local.gpu_node_pool[count.index].additional_userdata

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

  tags = var.tags

  ## TODO: nodes fails to join cluster when enabled
  ## Need to look into VM instance_profile IAM
  #
  # launch_template {
  #   id = aws_launch_template.gpu_ng[count.index].id
  #   version = aws_launch_template.gpu_ng[count.index].latest_version
  # }
  scaling_config {
    desired_size = local.gpu_node_pool[count.index].asg_desired_capacity
    max_size     = local.gpu_node_pool[count.index].asg_max_size
    min_size     = local.gpu_node_pool[count.index].asg_min_size
  }
  
  timeouts {
    create = "20m" #TODO: remove
  }

  depends_on = [
      module.autoscaling
  ]
}

resource "aws_autoscaling_group" "gpu_ng" {

  count = length(local.gpu_node_pool)

  name_prefix = "${var.prefix}-asg-${count.index}"
  vpc_zone_identifier = module.vpc.private_subnets

  health_check_type = "ELB"
  health_check_grace_period = 300
  default_cooldown = 10

  min_size = local.gpu_node_pool[count.index].asg_min_size 
  max_size = local.gpu_node_pool[count.index].asg_max_size
  desired_capacity = local.gpu_node_pool[count.index].asg_desired_capacity

  launch_template {
    id = aws_launch_template.gpu_ng[count.index].id
    version = aws_launch_template.gpu_ng[count.index].latest_version
  }
  
  lifecycle { create_before_destroy = true }
}
