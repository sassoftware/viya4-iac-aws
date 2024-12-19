###WAF Resource#######
resource "aws_wafv2_web_acl" "waf" {
  name        = "sas-awsng-${var.spoke_account_id}-acl"
  description = "Web ACL for WAF"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "myWebACL"
    sampled_requests_enabled   = true
  }
  rule {
    name     = "nextgen-awsng-BotControlRule"
    priority = 1
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
        version     = "Version_3.0"
      }
    }
    override_action {
      count {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "bot-control-metrics"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "nextgen-awsng-GeoRestrictionRule"
    priority = 2
    action {
      block {}
    }
    statement {
      geo_match_statement {
        country_codes = ["BY", "CU", "IR", "KP", "RU", "SY"]
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoRestrictionRule"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "nextgen-awsng-CoreRule"
    priority = 3
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    override_action {
      count {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "CoreRuleSetRule"
      sampled_requests_enabled   = true
    }
  }

  # # AWS Managed IP Reputation List
  rule {
    name     = "nextgen-awsng-IpReputationList"
    priority = 4
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    override_action {
      none {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPReputationRule"
      sampled_requests_enabled   = true
    }
  }

  # Known Bad Inputs
  rule {
    name     = "nextgen-awsng-Bad-Inputs-Rule"
    priority = 5
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    override_action {
      count {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "KnownBadInputsRule"
      sampled_requests_enabled   = true
    }
  }
  tags = merge(
    {
      "Name" = format("%s", "nextgen-awsng-${var.spoke_account_id}-acl")
    },
    var.tags
  )
}





