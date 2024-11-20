
# ####### Create CMK for each resource #################
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "cmk" {
  for_each = {
    for key in keys(local.key_names) :
    key => key if var.enable_nist_features && (
      key == "rds_key" ||
      key == "ebs_key" ||
      (key == "efs_key" && var.storage_type_backend == "efs") ||
      (key == "fsx_key" && var.storage_type_backend == "ontap")
    )
  }
  description             = "KMS key for ${each.value}"
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = local.tags
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Id" : "${each.value}-policy", # Unique identifier for the policy
    "Statement" : [
      {
        "Sid" : "Allow access through ${each.key} for all principals in the account",
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
        "Sid" : "Allow direct access to key metadata to the account",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : [
          "kms:Describe*",
          "kms:Get*",
          "kms:List*",
          "kms:RevokeGrant"
        ],
        "Resource" : "*"
      }
    ]
  })
}



resource "aws_kms_alias" "cmk" {
  for_each      = var.enable_nist_features ? { for key in keys(local.key_names) : key => key if contains(keys(aws_kms_key.cmk), key) } : {}
  name          = "alias/${local.key_names[each.key]}"
  target_key_id = aws_kms_key.cmk[each.key].key_id
}


