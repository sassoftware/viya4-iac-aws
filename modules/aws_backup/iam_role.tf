locals {
  policy_list = ["arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores", "${aws_iam_policy.ec2_pass_policy.arn}"]
}

data "aws_iam_policy_document" "assume_role" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup_operator_role" {
  name               = "${var.prefix}-${var.location}-${var.hub_environment}-backup-operator-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_managed_backup_operator" {
  role       = aws_iam_role.backup_operator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role" "restore_operator_role" {
  name               = "${var.prefix}-${var.location}-${var.hub_environment}-backup-restore-operator-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "aws_managed_restore_operator" {
  role       = aws_iam_role.restore_operator_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

data "aws_iam_policy_document" "ec2_pass" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${var.spoke_account_id}:role/*"]
  }
}
 
resource "aws_iam_policy" "ec2_pass_policy" {
  name   = "${var.prefix}-ec2-pass-policy-${var.hub_environment}-${var.location}"
  policy = data.aws_iam_policy_document.ec2_pass.json
}

 
resource "aws_iam_role_policy_attachment" "aws_managed_ec2_restore_operator" {
  depends_on = [aws_iam_policy.ec2_pass_policy]
  for_each   = { for k, v in local.policy_list : k => v }
  role       = aws_iam_role.restore_operator_role.name
  policy_arn = each.value
}


