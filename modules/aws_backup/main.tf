

resource "aws_backup_vault" "spoke" {
  name        = "sas-awsng-${var.spoke_account_id}-backup-vault"
  kms_key_arn = aws_kms_key.spoke_vault_key.arn
  tags = merge(
    var.tags,
    {
      Name = "sas-awsng-${var.spoke_account_id}-backup-vault"
    }
  )

}

resource "aws_backup_vault_lock_configuration" "spoke" {
  backup_vault_name   = aws_backup_vault.spoke.id
  changeable_for_days = "7"
  max_retention_days  = "30"
  min_retention_days  = "7"
  depends_on          = [aws_backup_vault.spoke]
}

resource "aws_backup_vault_policy" "spoke" {
  backup_vault_name = aws_backup_vault.spoke.name
  depends_on        = [aws_backup_vault.spoke, aws_iam_role.restore_operator_role, aws_iam_role.backup_operator_role]
  policy            = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "AWSLogDeliveryWrite20150319",
    "Statement": [
        {
            "Sid": "Allow backup operator actions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.backup_operator_role.arn}"
            },
            "Action": [
               "backup:DescribeBackupVault",
               "backup:GetBackupVaultAccessPolicy",
               "backup:ListRecoveryPointsByBackupVault",
               "backup:StartBackupJob"
            ],
            "Resource": "${aws_backup_vault.spoke.arn}"
        },
        {
            "Sid": "Deny Manual Deletion of Recovery point",
            "Effect": "Deny",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
              "backup:UpdateRecoveryPointLifecycle",
              "backup:DeleteRecoveryPoint",
              "backup:PutBackupVaultAccessPolicy"
            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow restore operator actions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.restore_operator_role.arn}"
            },
            "Action": [
                "backup:StartRestoreJob",
                "backup:ListRecoveryPointsByBackupVault",
                "backup:GetBackupVaultAccessPolicy",
                "backup:DescribeBackupVault"
            ],
            "Resource": "${aws_backup_vault.spoke.arn}"
        },
        {
            "Sid": "Allow backup copy by org members",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "backup:CopyfromBackupVault",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:PrincipalOrgID": "${var.org_id}"
                }
            }
        }
    ]
}
EOF
}

data "aws_caller_identity" "current" {}



resource "aws_backup_framework" "backup_compliance_framework" {
  depends_on = [ aws_backup_vault.spoke ]
  name        = "sas_awsng_${var.spoke_account_id}_backup_framework"
  description = "This framework validates Recovery Points created by AWS Backup"
  control {
    name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
    input_parameter {
      name  = "requiredRetentionDays"
      value = "21"
    }
  }
  control {
    name = "BACKUP_PLAN_MIN_FREQUENCY_AND_MIN_RETENTION_CHECK"
    input_parameter {
      name  = "requiredFrequencyUnit"
      value = "days"
    }
    input_parameter {
      name  = "requiredRetentionDays"
      value = "21"
    }
    input_parameter {
      name  = "requiredFrequencyValue"
      value = "1"
    }
  }
  control {
    name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
  }
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB"
        "FSx"
      ]
    }
  }
  control {
    name = "BACKUP_RECOVERY_POINT_MANUAL_DELETION_DISABLED"
  }

  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_CROSS_REGION"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB",
        "FSx"
      ]
    }
  }

  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_CROSS_ACCOUNT"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB",
        "FSx"
      ]
    }
  }

  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_VAULT_LOCK"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB",
        "FSx"
      ]
    }
  }

  control {
    name = "BACKUP_LAST_RECOVERY_POINT_CREATED"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB",
        "FSx"
      ]
    }

    input_parameter {
      name  = "recoveryPointAgeUnit"
      value = "days"
    }

    input_parameter {
      name  = "recoveryPointAgeValue"
      value = "1"
    }
  }

  control {
    name = "RESTORE_TIME_FOR_RESOURCES_MEET_TARGET"
    scope {
      compliance_resource_types = [
        "RDS",
        "Aurora",
        "EFS",
        "EC2",
        "EBS",
        # "DynamoDB",
        "FSx"
      ]
    }

    input_parameter {
      name  = "maxRestoreTime"
      value = "360"
    }
  }

  timeouts {
    create = "10m"
  }

  tags = {
    "Name"    = "sas-awsng-${var.spoke_account_id}-backup-framework"
    ManagedBy = "Terraform"
  }
}

# locals {
#   location_vault_map = {
#     "us-east-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "eu-central-1"   = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "ca-central-1"   = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "eu-west-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "ap-southeast-1" = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "ap-northeast-1" = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "ap-south-1"     = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "eu-west-3"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#     "us-west-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
#   }
# }

# resource "aws_backup_plan" "spoke" {
#   name = "sas-awsng-${var.spoke_account_id}-backup-plan"

#   dynamic "rule" {
#     for_each = var.spoke_backup_rules
#     content {
#       rule_name                = rule.value.name
#       target_vault_name        = aws_backup_vault.spoke.name
#       schedule                 = rule.value.schedule
#       start_window             = rule.value.start_window
#       completion_window        = rule.value.completion_window
#       recovery_point_tags      = rule.value.recovery_point_tags
#       enable_continuous_backup = rule.value.enable_continuous_backup

#       dynamic "lifecycle" {
#         for_each = lookup(rule.value, "lifecycle", null) != null ? [true] : []
#         content {
#           cold_storage_after = rule.value.lifecycle.cold_storage_after
#           delete_after       = rule.value.lifecycle.delete_after
#         }
#       }

#       # Copy action for EFS
#       dynamic "copy_action" {
#         for_each = contains(["efs_backup_rule_daily", "efs_backup_rule_weekly"], rule.value.name) ? [true] : []

#         content {
#           destination_vault_arn = var.central_backup_vault_us  # Example for US

#           dynamic "selection_tag" {
#             for_each = [for t in rule.value.recovery_point_tags : t if t.key == "Backup" && t.value == "efs"]

#             content {
#               type  = "STRINGEQUALS"
#               key   = "Backup"
#               value = "efs"
#             }
#           }

#           dynamic "lifecycle" {
#             for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

#             content {
#               cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
#               delete_after       = rule.value.copy_action.lifecycle.delete_after
#             }
#           }
#         }
#       }

#       # Copy action for RDS
#       dynamic "copy_action" {
#         for_each = contains(["rds_backup_rule_daily", "rds_backup_rule_weekly"], rule.value.name) ? [true] : []

#         content {
#           destination_vault_arn = lookup(local.location_vault_map, var.location, null)

#           dynamic "selection_tag" {
#             for_each = [for t in rule.value.recovery_point_tags : t if t.key == "Backup" && t.value == "rds"]

#             content {
#               type  = "STRINGEQUALS"
#               key   = "Backup"
#               value = "rds"
#             }
#           }

#           dynamic "lifecycle" {
#             for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

#             content {
#               cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
#               delete_after       = rule.value.copy_action.lifecycle.delete_after
#             }
#           }
#         }
#       }

#       # Copy action for FSx
#       dynamic "copy_action" {
#         for_each = contains(["fsx_backup_rule_daily", "fsx_backup_rule_weekly"], rule.value.name) ? [true] : []

#         content {
#           destination_vault_arn = var.central_backup_vault_us  # Example for US or a different FSx target

#           dynamic "selection_tag" {
#             for_each = [for t in rule.value.recovery_point_tags : t if t.key == "Backup" && t.value == "fsx"]

#             content {
#               type  = "STRINGEQUALS"
#               key   = "Backup"
#               value = "fsx"
#             }
#           }

#           dynamic "lifecycle" {
#             for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

#             content {
#               cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
#               delete_after       = rule.value.copy_action.lifecycle.delete_after
#             }
#           }
#         }
#       }

#     }
#   }

#   dynamic "advanced_backup_setting" {
#     for_each = var.advanced_backup_setting != null ? [true] : []
#     content {
#       backup_options = var.advanced_backup_setting.backup_options
#       resource_type  = var.advanced_backup_setting.resource_type
#     }
#   }

#   tags = merge(
#     var.tags,
#     {
#       Name        = "sas-awsng-${var.spoke_account_id}-backup-plan",
#       PolicyOwner = "NextGen"
#     }
#   )
# }

# resource "aws_backup_selection" "spoke" {
#   iam_role_arn = aws_iam_role.backup_operator_role.arn
#   name         = "sas-awsng-${var.spoke_account_id}-backup-selection"
#   plan_id      = aws_backup_plan.spoke.id

#   dynamic "selection_tag" {
#     for_each = ["efs", "rds", "fsx"]

#     content {
#       type  = "STRINGEQUALS"
#       key   = "Backup"
#       value = selection_tag.value
#     }
#   }
#}

locals {
  location_vault_map = {
    "us-east-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "eu-central-1"   = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "ca-central-1"   = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "eu-west-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "ap-southeast-1" = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "ap-northeast-1" = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "ap-south-1"     = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "eu-west-3"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
    "us-west-1"      = "arn:aws:backup:${var.location}:${var.backup_account_id}:backup-vault:sascloud-awsng-central-backup-vault-${var.hub_environment}"
  }
}

resource "aws_backup_plan" "spoke" {
  name = "sas-awsng-${var.spoke_account_id}-backup-plan"

  dynamic "rule" {
    for_each = var.spoke_backup_rules
    content {
      rule_name                = rule.value.name
      target_vault_name        = aws_backup_vault.spoke.name
      schedule                 = rule.value.schedule
      start_window             = rule.value.start_window
      completion_window        = rule.value.completion_window
      recovery_point_tags      = rule.value.recovery_point_tags
      enable_continuous_backup = rule.value.enable_continuous_backup

      dynamic "lifecycle" {
        for_each = lookup(rule.value, "lifecycle", null) != null ? [true] : []
        content {
          cold_storage_after = rule.value.lifecycle.cold_storage_after
          delete_after       = rule.value.lifecycle.delete_after
        }
      }

      # Apply copy action for EFS to US vault
      dynamic "copy_action" {
          for_each = contains(["efs_backup_rule_daily", "efs_backup_rule_weekly"], rule.value.name) ? [true] : []

        content {
          destination_vault_arn = var.central_backup_vault_us

          dynamic "lifecycle" {
            for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

            content {
              cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
              delete_after       = rule.value.copy_action.lifecycle.delete_after
            }
          }
        }
      }

      # Apply copy action for EFS to EU vault
      dynamic "copy_action" {
          for_each = contains(["efs_backup_rule_daily", "efs_backup_rule_weekly"], rule.value.name) ? [true] : []

        content {
          destination_vault_arn = var.central_backup_vault_eu

          dynamic "lifecycle" {
            for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

            content {
              cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
              delete_after       = rule.value.copy_action.lifecycle.delete_after
            }
          }
        }
      }

      # Apply region-based copy action for RDS
      dynamic "copy_action" {
        for_each = contains(["rds_backup_rule_daily", "rds_backup_rule_weekly"], rule.value.name) ? [true] : []

        content {
          destination_vault_arn = lookup(local.location_vault_map, var.location, null) 

          dynamic "lifecycle" {
            for_each = try(lookup(rule.value.copy_action, "lifecycle", null), null) != null ? [true] : []

            content {
              cold_storage_after = rule.value.copy_action.lifecycle.cold_storage_after
              delete_after       = rule.value.copy_action.lifecycle.delete_after
            }
          }
        }
      }

      # # No copy action for FSx
      # dynamic "copy_action" {
      #   for_each = contains(rule.value.name, "fsx") ? [] : [true]
      #   content {
      #     destination_vault_arn = aws_backup_vault.spoke.arn
      #   }
      # }
    }
  }

  dynamic "advanced_backup_setting" {
    for_each = var.advanced_backup_setting != null ? [true] : []
    content {
      backup_options = var.advanced_backup_setting.backup_options
      resource_type  = var.advanced_backup_setting.resource_type
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "sas-awsng-${var.spoke_account_id}-backup-plan",
      PolicyOwner = "NextGen"
    }
  )
}

resource "aws_backup_selection" "spoke" {
  iam_role_arn = aws_iam_role.backup_operator_role.arn
  name         = "sas-awsng-${var.spoke_account_id}-backup-selection"
  plan_id      = aws_backup_plan.spoke.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "Enabled"
  }
}




