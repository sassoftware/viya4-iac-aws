# Copyright © 2021-2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Permissions based off the IAM Policies required to manage fsx_ontap resources in this project
data "aws_iam_policy_document" "fsx_ontap" {
  # Statement for FSx File System ownership permissions
  statement {
    sid       = "fsxFileSystemOwn"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "fsx:CreateFileSystem", # Permission to create a new FSx file system
      "fsx:UpdateFileSystem", # Permission to update an existing FSx file system
      "fsx:UntagResource",    # Permission to remove tags from FSx resources
      "fsx:CreateBackup",     # Permission to create a backup of the FSx file system
      "fsx:TagResource",      # Permission to add or update tags on FSx resources
      "fsx:DeleteFileSystem", # Permission to delete an FSx file system
    ]
  }

  # Statement for FSx File System full access permissions
  statement {
    sid       = "fsxFileSystemAll"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:*/*"]

    actions = [
      "fsx:CreateVolume",                # Permission to create a new volume in FSx
      "fsx:DeleteStorageVirtualMachine", # Permission to delete a storage virtual machine
      "fsx:UpdateVolume",                # Permission to update an existing volume
      "fsx:CreateStorageVirtualMachine", # Permission to create a storage virtual machine
      "fsx:DeleteVolume",                # Permission to delete a volume in FSx
    ]
  }

  # Statement for FSx Volume ownership permissions
  statement {
    sid       = "fsxVolumeOwn"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:volume/*"]

    actions = [
      "fsx:CreateVolume", # Permission to create a new volume
      "fsx:UpdateVolume", # Permission to update an existing volume
      "fsx:DeleteVolume", # Permission to delete a volume
    ]
  }

  # Statement for describing FSx resources
  statement {
    sid       = "fsxDescribeAll"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "fsx:DescribeFileSystems",            # Permission to describe FSx file systems
      "fsx:DescribeVolumes",                # Permission to describe FSx volumes
      "fsx:DescribeStorageVirtualMachines", # Permission to describe storage virtual machines in FSx
      "fsx:UntagResource",                  # Permission to remove tags from FSx resources
      "fsx:TagResource",                    # Permission to add or update tags on FSx resources
    ]
  }

  # Statement for listing tags on FSx resources
  statement {
    sid       = "fsxListTagsAll"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:*/*"]
    actions   = ["fsx:ListTagsForResource"] # Permission to list tags for FSx resources
  }
}

# IAM Policy resource for FSx ONTAP
resource "aws_iam_policy" "fsx_ontap" {

  name_prefix = "${var.prefix}-fsx-ontap"                   # Prefix for the policy name
  description = "FSx policy for user or assumed-role"       # Description of the policy
  policy      = data.aws_iam_policy_document.fsx_ontap.json # Policy document in JSON format
  tags        = var.tags                                    # Tags to apply to the policy
}

# IAM User Policy Attachment resource
resource "aws_iam_user_policy_attachment" "attachment" {
  count      = var.is_user ? 1 : 0          # Attach policy only if var.is_user is true
  user       = var.iam_user_name            # IAM user name to attach the policy
  policy_arn = aws_iam_policy.fsx_ontap.arn # ARN of the FSx ONTAP policy
}

# IAM Role Policy Attachment resource
resource "aws_iam_role_policy_attachment" "attachment" {
  count      = var.is_user ? 0 : 1          # Attach policy only if var.is_user is false
  role       = var.iam_role_name            # IAM role name to attach the policy
  policy_arn = aws_iam_policy.fsx_ontap.arn # ARN of the FSx ONTAP policy
}
