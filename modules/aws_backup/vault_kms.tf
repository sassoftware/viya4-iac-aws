resource "aws_kms_key" "spoke_vault_key" {
  description             = "kms key for vault"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  is_enabled              = true

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "All root user access to all key operations",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "arn:aws:iam::${var.backup_account_id}:root"
          ]
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow backup/restore operators access to the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "${aws_iam_role.restore_operator_role.arn}",
            "${aws_iam_role.backup_operator_role.arn}",
            "${var.central_backup_operator}",
            "${var.central_restore_operator}"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : {
            "aws:PrincipalOrgID" : "${var.org_id}"
          }
        }
      }
    ]
  })

  tags = var.tags

}

resource "aws_kms_alias" "spoke_vault_key_alias" {
  name          = "alias/sas-awsng-${var.location}-backup-kms"
  target_key_id = aws_kms_key.spoke_vault_key.key_id
}