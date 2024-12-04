# AWS IAM Access Analyzer External
resource "aws_accessanalyzer_analyzer" "aws_access_analyzer_external" {
  analyzer_name = "sas-awsng-accessanalyzer-ext-${var.location}"
  type          = var.analyzer_type_external
  tags = var.tags
}

# AWS IAM Access Analyzer Unused
resource "aws_accessanalyzer_analyzer" "aws_access_analyzer_unused" {
  analyzer_name = "sas-awsng-accessanalyzer-unused-${var.location}"
  type          = var.analyzer_type_unused
  configuration {
    unused_access {
      unused_access_age = 90
    }
  }
  tags = var.tags
}

# IAM Role for Access Analyzer
resource "aws_iam_role" "access_analyzer_role" {
  name = "sas-awsng-iam-analyzer-${var.location}-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "access-analyzer.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
  tags = var.tags
}

# IAM Policy for Access Analyzer
resource "aws_iam_policy" "access_analyzer_policy" {
  name        = "sas-awsng-iam-analyzer-${var.location}-policy"
  description = "IAM policy for Access Analyzer"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "access-analyzer:*",
      Resource = "*"
    }]
  })

  tags = var.tags
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "access_analyzer_policy_attachment" {
  role       = aws_iam_role.access_analyzer_role.name
  policy_arn = aws_iam_policy.access_analyzer_policy.arn
}