# Copyright © 2021-2024, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

# Permissions based off the IAM Policies required to manage fsx_ontap resources in this project
data "aws_iam_policy_document" "fsx_ontap" {
  statement {
    sid       = "fsxFileSystemOwn"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "fsx:CreateFileSystem",
      "fsx:UpdateFileSystem",
      "fsx:UntagResource",
      "fsx:CreateBackup",
      "fsx:TagResource",
      "fsx:DeleteFileSystem",
    ]
  }

  statement {
    sid       = "fsxFileSystemAll"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:*/*"]

    actions = [
      "fsx:CreateVolume",
      "fsx:DeleteStorageVirtualMachine",
      "fsx:UpdateVolume",
      "fsx:CreateStorageVirtualMachine",
      "fsx:DeleteVolume",
    ]
  }

  statement {
    sid       = "fsxVolumeOwn"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:volume/*"]

    actions = [
      "fsx:CreateVolume",
      "fsx:UpdateVolume",
      "fsx:DeleteVolume",
    ]
  }

  statement {
    sid       = "fsxDescribeAll"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "fsx:DescribeFileSystems",
      "fsx:DescribeVolumes",
      "fsx:DescribeStorageVirtualMachines",
      "fsx:UntagResource",
      "fsx:TagResource",
    ]
  }

  statement {
    sid       = "fsxListTagsAll"
    effect    = "Allow"
    resources = ["arn:aws:fsx:*:*:*/*"]
    actions   = ["fsx:ListTagsForResource"]
  }
}

resource "aws_iam_policy" "fsx_ontap" {

  name_prefix = "${var.prefix}-fsx-ontap"
  description = "FSx policy for user or assumed-role"
  policy      = data.aws_iam_policy_document.fsx_ontap.json
  tags        = var.tags
}

resource "aws_iam_user_policy_attachment" "attachment" {
  count = var.is_user ? 1 : 0

  user       = var.iam_user_name
  policy_arn = aws_iam_policy.fsx_ontap.arn
}

resource "aws_iam_role_policy_attachment" "attachment" {
  count = var.is_user ? 0 : 1

  role       = var.iam_role_name 
  policy_arn = aws_iam_policy.fsx_ontap.arn
}