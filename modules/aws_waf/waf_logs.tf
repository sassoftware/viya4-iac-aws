resource "aws_iam_policy" "waf_logging_policy" {
  depends_on = [aws_wafv2_web_acl.waf]
  name       = "sas-awsng-${var.location}-waf-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "wafv2:PutLoggingConfiguration",
          "wafv2:DeleteLoggingConfiguration"
        ],
        "Resource" : [
          "*"
        ],
        "Effect" : "Allow",
        "Sid" : "LoggingConfigurationAPI"
      },
      {
        "Sid" : "WebACLLogDelivery",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:DeleteLogDelivery"
        ],
        "Resource" : "*",
        "Effect" : "Allow"
      },
      {
        "Sid" : "WebACLLoggingS3",
        "Action" : [
          "s3:PutBucketPolicy",
          "s3:GetBucketPolicy"
        ],
        "Resource" : [
          var.local_s3_bucket_arn
        ],
        "Effect" : "Allow"
      }
    ]
  })
  tags = var.tags
  # policy = data.aws_iam_policy_document.waf_logging_policy.json
}

resource "aws_iam_role" "waf_logging_role" {
  depends_on         = [aws_wafv2_web_acl.waf]
  name               = "sas-awsng-${var.location}-waf-logging-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "waf.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags               = var.tags
}

# Attach the logging policy to the IAM role
resource "aws_iam_role_policy_attachment" "waf_logging_policy_attachment" {
  depends_on = [aws_wafv2_web_acl.waf]
  role       = aws_iam_role.waf_logging_role.name
  policy_arn = aws_iam_policy.waf_logging_policy.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  depends_on              = [aws_wafv2_web_acl.waf]
  resource_arn            = aws_wafv2_web_acl.waf.arn
  log_destination_configs = [var.local_s3_bucket_arn]
  redacted_fields {
    uri_path {}
  }
}


