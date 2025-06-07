# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# IAM policy for the EBS CSI driver in an EKS cluster
resource "aws_iam_policy" "ebs_csi" {
  # Create a unique name for the policy using the provided prefix and the policy type
  name_prefix = "${var.prefix}-ebs-csi-policy"
  # Description of the policy, including the cluster name for context
  description = "EKS ebs csi policy for cluster ${var.cluster_name}"
  # Tags to apply to the policy for management and organization
  tags = var.tags

  # The policy document that defines the permissions granted by this policy
  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateSnapshot",
        "ec2:AttachVolume",
        "ec2:DetachVolume",
        "ec2:ModifyVolume",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeInstances",
        "ec2:DescribeSnapshots",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DescribeVolumesModifications"
      ],
      # Allow these actions on all resources
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateTags"
      ],
      # Restrict tag creation to specific resources: volumes and snapshots
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ],
      "Condition": {
        "StringEquals": {
          "ec2:CreateAction": [
            "CreateVolume",
            "CreateSnapshot"
          ]
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteTags"
      ],
      # Restrict tag deletion to specific resources: volumes and snapshots
      "Resource": [
        "arn:aws:ec2:*:*:volume/*",
        "arn:aws:ec2:*:*:snapshot/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      # Allow volume creation with specific tags
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      # Allow volume creation if the CSIVolumeName tag is present
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVolume"
      ],
      # Allow volume creation for volumes owned by the cluster
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      # Allow volume deletion with specific resource tags
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      # Allow volume deletion if the CSIVolumeName tag is present on the resource
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteVolume"
      ],
      # Allow volume deletion for volumes owned by the cluster
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/kubernetes.io/cluster/*": "owned"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      # Allow snapshot deletion if the CSIVolumeSnapshotName tag is present on the resource
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/CSIVolumeSnapshotName": "*"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DeleteSnapshot"
      ],
      # Allow snapshot deletion with specific resource tags
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "ec2:ResourceTag/ebs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
EOT
}

# Module to create an IAM role that can be assumed by the EBS CSI driver using OIDC
module "iam_assumable_role_with_oidc" {
  # Source of the module, pointing to the IAM module in the Terraform AWS Modules collection
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  # Version constraint for the module
  version = "~> 5.0"

  # Enable role creation
  create_role = true
  # Name of the role, following the naming convention with the provided prefix
  role_name = "${var.prefix}-ebs-csi-role"
  # OIDC provider URL, formatted as required by the module
  provider_url = replace(var.oidc_url, "https://", "")
  # Attach the previously created policy to this role
  role_policy_arns = [aws_iam_policy.ebs_csi.arn]
  # Audience and subject for the OIDC provider, specific to the EBS CSI controller service account
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
  oidc_fully_qualified_subjects  = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]

  # Tags to apply to the role, merging module-specific and user-defined tags
  tags = merge(
    {
      Role = "${var.prefix}-ebs-csi-role"
    },
    var.tags
  )
}

# Attach the IAM policy to the role created by the module
resource "aws_iam_role_policy_attachment" "ebs_attachment" {
  # Role to attach the policy to, obtained from the module output
  role = module.iam_assumable_role_with_oidc.iam_role_name
  # ARN of the policy to attach
  policy_arn = aws_iam_policy.ebs_csi.arn
}
