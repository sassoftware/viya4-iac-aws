# # SNS Notification
resource "aws_sns_topic" "user_updates" {
  name              = "SAS-AWS-NextGen-SNS-topic"
  kms_master_key_id = aws_kms_alias.sns_kms.target_key_id
  tags              = var.tags
}
 
data "aws_iam_policy_document" "sns_topic_policy" {
  policy_id = "__default_policy_ID"
 
  statement {
    actions = [
      "SNS:GetTopicAttributes",
      "SNS:SetTopicAttributes",
      "SNS:AddPermission",
      "SNS:RemovePermission",
      "SNS:DeleteTopic",
      "SNS:Subscribe",
      "SNS:ListSubscriptionsByTopic",
      "SNS:Publish",
      "SNS:Receive"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        var.spoke_account_id
      ]
    }
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = [
      aws_sns_topic.user_updates.arn
    ]
    sid = "__default_statement_ID"
  }
 
  statement {
    actions = ["sns:Publish"]
    sid     = "SNSEncryptionIntegrationWithCloudWatch"
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        var.spoke_account_id
      ]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
 
    resources = [
      aws_sns_topic.user_updates.arn
    ]
  }
}
 
resource "aws_sns_topic_policy" "policy_attachment" {
  arn = aws_sns_topic.user_updates.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}
 
resource "aws_sns_topic_subscription" "user_updates_email_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "https"
  endpoint  =  var.hub_environment == "prod" ? "https://srvc_em_aws_cloudwatch:5_SAtJEy9LuYTb)UKC9rHXvM@sas.service-now.com/api/sn_em_connector/em/inbound_event?source=aws" : "https://srvc_azure_monitor:Za7zlnEMLLHckpE@sasdev.service-now.com/api/sn_em_connector/em/inbound_event?source=aws"
}
 
resource "aws_kms_key" "cloudwatch_to_sns" {
  enable_key_rotation     = true
  rotation_period_in_days = 90
  description             = "KMS CMK key for CloudWatch to SNS Integration"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Id" : "kms-sns-${var.hub_environment}-${var.location}",
      "Statement" : [
        {
          "Sid" : "Allow access through for all principals in the account that are authorized to use the key",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : [
              "arn:aws:iam::${var.spoke_account_id}:root"
            ]
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "SNSEncryptionIntegrationWithCloudWatch",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : [
              "cloudwatch.amazonaws.com"
            ]
          },
          "Action" : [
            "kms:GenerateDataKey*",
            "kms:DescribeKey",
            "kms:Decrypt"
          ],
          "Resource" : "*"
        }
      ]
    }
  )
 
  tags = {
    managedBy = "Terraform"
  }
}
 
resource "aws_kms_alias" "sns_kms" {
  name          = "alias/${var.prefix}-sns-key"
  target_key_id = aws_kms_key.cloudwatch_to_sns.key_id
}
 

# ########## RDS Postgres Instances #########
# # CloudWatch Alarm for RDS CPU Utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu_utilization" {
  alarm_name          = "${var.prefix}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "900"
  statistic           = "Average"
  threshold           = var.cpu_threshold
  actions_enabled     = true
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The CPU Utilization for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql" //var.instance_id
  }
}

# # # CloudWatch Alarm for RDS Write IOPS
resource "aws_cloudwatch_metric_alarm" "rds_write_iops" {
  alarm_name          = "${var.prefix}-RDS-Write-IOPS-Alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteIOPS"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 1000 # Adjust the threshold based on your requirements
  alarm_description   = "Severity-02- CloudWatch Alert : [AWS] [NextGen] on RDS : The read IOPS  for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

# CloudWatch Alarm for RDS READ IOPS
resource "aws_cloudwatch_metric_alarm" "rds_read_iops" {
  alarm_name          = "${var.prefix}-RDS-Read-IOPS-Alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadIOPS"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 1000 # Adjust the threshold based on your requirements
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The write IOPS  for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

# CloudWatch Alarm for RDS Network Receive Throughput
resource "aws_cloudwatch_metric_alarm" "rds_network_receive_throughput" {
  alarm_name          = "${var.prefix}-RDS-Network-Receive-Throughput-Alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkReceiveThroughput"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 1000000 # Adjust the threshold based on your requirements
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The Network receive throughput for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

# # CloudWatch Alarm for RDS Network Transmit Throughput

resource "aws_cloudwatch_metric_alarm" "rds_network_transmit_throughput" {
  alarm_name          = "${var.prefix}-RDS-Network-Transmit-Throughput-Alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NetworkReceiveThroughput"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 1000000 # Adjust the threshold based on your requirements
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The Network transmit throughput for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

#CloudWatch Alarm for RDS Freeable Memory
resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory" {
  alarm_name          = "${var.prefix}-RDS-Free-Memory-Alert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeableMemory"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 500000000 # Adjust the threshold based on your requirements (in bytes)
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The Free memory for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

# # CloudWatch Alarm for RDS Free Storage Space
resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${var.prefix}-RDS-Free-Storage-Alert"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 900
  statistic           = "Average"
  threshold           = 10000000000 # Adjust the threshold based on your requirements (in bytes)
  alarm_description   = "Severity-02 - CloudWatch Alert : [AWS] [NextGen] on RDS : The disk space Utilization for ${var.prefix}-default-pgsql is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    DBInstanceIdentifier = "${var.prefix}-default-pgsql"
  }
}

# ###EFS##############
resource "aws_cloudwatch_metric_alarm" "efs_client_connections" {
  count               = var.storage_type_backend == "efs" ? 1 : 0
  alarm_name          = "${var.prefix}-EFS-Client-Connections-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ClientConnections"
  namespace           = "AWS/EFS"
  period              = "900" # 5 minutes
  statistic           = "Average"
  threshold           = "90" # Set your desired threshold
  alarm_description   = "Severity-03 - CloudWatch Alert : [AWS] [NextGen] on EFS : The Client connection for ${var.prefix}-efs is above the threshold for defined threshold"
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    FileSystemId = var.efs_id
  }
}
resource "aws_cloudwatch_metric_alarm" "efs_total_io_bytes" {
  count               = var.storage_type_backend == "efs" ? 1 : 0
  alarm_name          = "${var.prefix}-EFS-Total-IO-Bytes-Alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TotalIOBytes"
  namespace           = "AWS/EFS"
  period              = "900" # 5 minutes
  statistic           = "Sum"
  threshold           = "9000000000" # Set your desired threshold
  alarm_description   = "Severity-03 - CloudWatch Alert : [AWS] [NextGen] on EFS : The IO bytes for ${var.prefix}-efs is above the threshold for defined threshold"
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    FileSystemId = var.efs_id
  }
}

##FSX####
# # # Alarm for storage capacity
resource "aws_cloudwatch_metric_alarm" "fsx_storage_capacity" {
  count               = var.storage_type_backend == "ontap" ? 1 : 0
  alarm_name          = "${var.prefix}-fsx-storage-capacity-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StorageCapacity"
  namespace           = "AWS/FSx"
  period              = 900
  statistic           = "Average"
  threshold           = 9000000000 # Change threshold percentage as needed
  alarm_description   = "Severity-03 - CloudWatch Alert : [AWS] [NextGen] on FSx : The Storage capacity for ${var.prefix}-fsx is above the threshold for defined threshold"
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
   dimensions = {
    FileSystemId = var.fsx_id
    DataType = "All"
    StorageTier = "SSD"
  }
}
# # # Alarm for storage used
resource "aws_cloudwatch_metric_alarm" "fsx_storage_used" {
  count               = var.storage_type_backend == "ontap" ? 1 : 0
  alarm_name          = "${var.prefix}-fsx-storage-used-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "StorageUsed"
  namespace           = "AWS/FSx"
  period              = 900
  statistic           = "Average"
  threshold           = 9000000000 # Change threshold percentage as needed
  alarm_description   = "Severity-03 - CloudWatch Alert : [AWS] [NextGen] on FSx : The Storage used for ${var.prefix}-fsx is above the threshold for defined threshold"
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    FileSystemId = var.fsx_id
  }
}

# ######## CloudWatch Billing Alarm ########

resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name          = "SAS_NextGen_billing_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EstimatedCharges"
  namespace           = "AWS/Billing"
  period              = "21600"
  statistic           = "Maximum"
  threshold           = var.billing_threshold
  alarm_description   = "Severity-03 - CloudWatch Alert : [AWS] [NextGen] on resource billing : The Billing for the resources is above the threshold for defined threshold"
  actions_enabled     = true
  alarm_actions       = [aws_sns_topic.user_updates.arn]

  dimensions = {
    Currency = "USD"
  }
}

