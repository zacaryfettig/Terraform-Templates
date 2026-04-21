resource "aws_wafv2_web_acl" "wafv2" {
  name        = "wafv2"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "rule-1"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "ratelimit"
      sampled_requests_enabled   = true
    }
  }

 # rule {
 #   name = "name1"
 #   priority = 2
#
#    action {
#      block {}
#    }

#    statement {
#        sqli_match_statement {
#
#            field_to_match {
#              body {}
#            }

#            text_transformation {
#              priority = 5
#              type     = "URL_DECODE"
#            }
#      }
#    }

#    visibility_config {
#      cloudwatch_metrics_enabled = false
#      metric_name                = "friendly-rule-metric-name"
#      sampled_requests_enabled   = false
#    }
#  }
  
rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "CommonRules"
      sampled_requests_enabled   = true
    }
}


rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 4
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
      
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "SQLiRules"
      sampled_requests_enabled   = true
    }
}

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "Rules"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "wafAssociation" {
  resource_arn = aws_lb.ecsLB.arn
  web_acl_arn  = aws_wafv2_web_acl.wafv2.arn
}