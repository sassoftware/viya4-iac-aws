# ---------- SPOKE ACCOUNT LOG BUCKET  ---------- #

data "aws_caller_identity" "current" {}



resource "aws_s3_bucket" "local_s3_bucket" {
  bucket              = "aws-waf-logs-infra-${var.spoke_account_id}-${var.location}-bkt"
  force_destroy       = var.force_destroy
  object_lock_enabled = true
  tags = merge(
    {
      "Name" = format("%s", "aws-waf-logs-infra-${var.spoke_account_id}-${var.location}-bkt"),
    },
    var.tags
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_local" {
  bucket = aws_s3_bucket.local_s3_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "log-prefix" {
  depends_on         = [aws_s3_bucket.local_s3_bucket]
  for_each           = toset(var.prefixes)
  bucket             = aws_s3_bucket.local_s3_bucket.id
  content_encoding   = "ContentMD5"
  checksum_algorithm = "CRC32C"
  key                = "${each.value}/"
 
  lifecycle {
    ignore_changes = [object_lock_retain_until_date, object_lock_mode]
  }
}

resource "aws_s3_bucket_public_access_block" "access_block_local" {
  bucket                  = aws_s3_bucket.local_s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "bucket_versioning_local" {
  bucket = aws_s3_bucket.local_s3_bucket.id
  versioning_configuration {
    status     = "Enabled"
    mfa_delete = "Disabled"
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "log_bkt_lifecycle_local" {
  bucket = aws_s3_bucket.local_s3_bucket.id
  rule {
    id = "spoke-rule"
    filter {} # enabling lifecycle configuration on all objects in the bucket
    expiration {
      days = 30
    }
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
    status = "Enabled"
  }
}
############### aws_s3_bucket_replication_configuration ################
data "aws_iam_policy_document" "assume_role_local" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.logging_account}:role/sascloud-awsng-logging-cross-account-iam-role"]
    }
    actions = ["sts:AssumeRole"]
  }
}
resource "aws_iam_role" "replication_role_local" {
  name               = "sas-awsng-${var.location}-${var.hub_environment}-replication-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_local.json
  tags               = var.tags
}
data "aws_iam_policy_document" "replication_json" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:GetObjectRetention",
      "s3:GetObjectLegalHold"
    ]
    resources = [
      "${aws_s3_bucket.local_s3_bucket.arn}/*",
      "${aws_s3_bucket.local_s3_bucket.arn}",
      "${var.central_logging_bucket}/*",
      "${var.central_logging_bucket}"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:ObjectOwnerOverrideToBucketOwner"
    ]
    resources = ["${aws_s3_bucket.local_s3_bucket.arn}/*",
    "${var.central_logging_bucket}/*"]
  }
}
resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.local_s3_bucket.id
  policy = <<EOF
  {
    "Version": "2012-10-17",
    "Id": "AWSLogDeliveryWrite20150319",
    "Statement": [
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                "delivery.logs.amazonaws.com",
                "logdelivery.elasticloadbalancing.amazonaws.com"
              ]
            },
            "Action": "s3:PutObject",
            "Resource": [
              "${aws_s3_bucket.local_s3_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
              "${aws_s3_bucket.local_s3_bucket.arn}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control",
                    "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:logs:${var.location}:${data.aws_caller_identity.current.account_id}:*"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.local_s3_bucket.arn}",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:logs:${var.location}:${data.aws_caller_identity.current.account_id}:*"
                }
            }
        },
        {
            "Sid": "S3PolicyStmt-DO-NOT-MODIFY-1722947266867",
            "Effect": "Allow",
            "Principal": {
                "Service": "logging.s3.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.local_s3_bucket.arn}/s3-access/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
                }
            }
        },
        {
            "Sid": "Allow ALB logs",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${local.account_id}:root"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.local_s3_bucket.arn}/*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "replication_policy_local" {
  name   = "sas-awsng-${var.location}-${var.hub_environment}-replication-policy"
  policy = data.aws_iam_policy_document.replication_json.json
  tags   = var.tags
}
resource "aws_iam_role_policy_attachment" "replication_local" {
  role       = aws_iam_role.replication_role_local.name
  policy_arn = aws_iam_policy.replication_policy_local.arn
}
resource "aws_s3_bucket_replication_configuration" "replication_local_config" {
  role   = aws_iam_role.replication_role_local.arn
  bucket = aws_s3_bucket.local_s3_bucket.id
  rule {
    id       = "cross-account-replication"
    status   = "Enabled"
    priority = 0
    filter {
      prefix = ""
    }
    delete_marker_replication {
      status = "Disabled"
    }
    destination {
      account = 730335345263
      access_control_translation {
        owner = "Destination"
      }
      bucket = var.central_logging_bucket
    }
  }
}


