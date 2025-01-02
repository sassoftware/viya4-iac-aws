data "external" "waf_checker_tool" {
  program = ["bash", "${path.module}/check_waf.sh", var.spoke_account_id, var.location, var.aws_access_key_id, var.aws_secret_access_key, var.aws_session_token]
  query = {
    "spoke_account_id" = var.spoke_account_id
    "location"         = var.location
    "access_key"       = var.aws_access_key_id
    "secret_key"       = var.aws_secret_access_key
    "token"            = var.aws_session_token
  }
}

data "external" "bucket_checker_tool" {
  program = ["bash", "${path.module}/bucket_checker.sh", var.spoke_account_id, var.location, var.aws_access_key_id, var.aws_secret_access_key, var.aws_session_token]
  query = {
    "spoke_account_id" = var.spoke_account_id
    "location"         = var.location
    "access_key"       = var.aws_access_key_id
    "secret_key"       = var.aws_secret_access_key
    "token"            = var.aws_session_token
  }
}

data "external" "analyzer_checker_tool" {
  program = ["bash", "${path.module}/analyzer_checker.sh", var.location, var.aws_access_key_id, var.aws_secret_access_key, var.aws_session_token]
  query = {
    "location"      = var.location
    "analyzer_name" = var.analyzer_name
    "access_key"    = var.aws_access_key_id
    "secret_key"    = var.aws_secret_access_key
    "token"         = var.aws_session_token
  }
}

data "external" "vault_checker_tool" {
  program = ["bash", "${path.module}/check_backupvault.sh", var.spoke_account_id, var.location, var.aws_access_key_id, var.aws_secret_access_key, var.aws_session_token, "sas-awsng-${var.spoke_account_id}-backup-vault"]
  query = {
    "spoke_account_id" = var.spoke_account_id
    "location"         = var.location
    "access_key"       = var.aws_access_key_id
    "secret_key"       = var.aws_secret_access_key
    "token"            = var.aws_session_token
    "VAULT_NAME"       = "ng-${var.spoke_account_id}-backup-vault"
  }
}


