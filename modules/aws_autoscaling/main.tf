# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0


# Permissions based off the IAM Policy recommended by kubernetes/autoscaler
# https://github.com/kubernetes/autoscaler/blob/cluster-autoscaler-chart-9.25.0/cluster-autoscaler/cloudprovider/aws/README.md
data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeImages",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "eks:DescribeNodegroup"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup"
    ]

    resources = ["*"]

    # Remove the following conditions that are incorrect for eks:DescribeNodegroup
    # condition {
    #   test     = "StringEquals"
    #   variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
    #   values   = ["owned"]
    # }

    # condition {
    #   test     = "StringEquals"
    #   variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
    #   values   = ["true"]
    # }
  }
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "${var.prefix}-eks-worker-autoscaling"
  description = "EKS worker node autoscaling policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
  tags        = var.tags
}

module "iam_assumable_role_with_oidc" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "~> 5.0"

  create_role                   = true
  role_name                     = "${var.prefix}-cluster-autoscaler"
  provider_url                  = replace(var.oidc_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.worker_autoscaling.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"]

  tags = merge(
    {
      Role = "${var.prefix}-cluster-autoscaler"
    },
    var.tags
  )
}

