# # SNS Notification
resource "aws_sns_topic" "user_updates" {
  name              = "SAS-AWS-NextGen-SNS-topic"
  kms_master_key_id = "alias/aws/sns"
}
resource "aws_sns_topic_subscription" "user_updates_email_target" {
  topic_arn = aws_sns_topic.user_updates.arn
  protocol  = "https"
  endpoint  = "https://srvc_azure_monitor:Za7zlnEMLLHckpE@sasdev.service-now.com/api/sn_em_connector/em/inbound_event?source=aws"
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
  alarm_description   = "Alarm if CPU utilization exceeds threshold"
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
  alarm_description   = "Alarm when RDS write IOPS exceeds the threshold"
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
  alarm_description   = "Alarm when RDS read IOPS exceeds the threshold"
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
  alarm_description   = "Alarm when RDS network receive throughput exceeds the threshold"
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
  alarm_description   = "Alarm when RDS network transmit throughput exceeds the threshold"
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
  alarm_description   = "Alarm when RDS free memory is below the threshold"
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
  alarm_description   = "Alarm when RDS free disk space is below the threshold"
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
  alarm_description   = "Alarm when EFS client connections exceed 10"
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
  threshold           = "1000000" # Set your desired threshold
  alarm_description   = "Alarm when EFS total IO bytes exceed 1,000,000"
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
  threshold           = 90 # Change threshold percentage as needed
  alarm_description   = "Alarm when FSx storage capacity exceeds 90%."
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    FileSystemId = var.fsx_id
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
  threshold           = 90 # Change threshold percentage as needed
  alarm_description   = "Alarm when FSx storage used exceeds 90%."
  alarm_actions       = [aws_sns_topic.user_updates.arn] # Add SNS topic ARN for notifications
  dimensions = {
    FileSystemId = var.fsx_id
  }
}



