resource "aws_sns_topic" "cost_alerts" {
  name = "${local.name}-cost-alerts"
}

# AWS Budgets and Cost Anomaly Detection publish to the topic.
data "aws_iam_policy_document" "cost_alerts" {
  statement {
    sid       = "AllowCostServicesToPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cost_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com", "costalerts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [split(":", aws_sns_topic.cost_alerts.arn)[4]]
    }
  }
}

resource "aws_sns_topic_policy" "cost_alerts" {
  arn    = aws_sns_topic.cost_alerts.arn
  policy = data.aws_iam_policy_document.cost_alerts.json
}

resource "aws_sns_topic_subscription" "cost_alerts_email" {
  topic_arn = aws_sns_topic.cost_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_budgets_budget" "service" {
  name         = "${local.name}-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
  metrics      = ["AmortizedCost"]

  filter_expression {
    and {
      tags {
        key    = "service"
        values = [var.service]
      }
    }
    and {
      tags {
        key    = "environment"
        values = [var.environment]
      }
    }
  }

  # Early warning: the month is on track to end over budget.
  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = [aws_sns_topic.cost_alerts.arn]
  }
}

resource "aws_ce_anomaly_monitor" "service" {
  name         = local.name
  monitor_type = "CUSTOM"

  # Watches only the costs tagged with this service. The null keys match
  # what the API returns and keep the plan free of false changes.
  monitor_specification = jsonencode({
    And            = null
    CostCategories = null
    Dimensions     = null
    Not            = null
    Or             = null
    Tags = {
      Key          = "service"
      MatchOptions = null
      Values       = [var.service]
    }
  })
}

resource "aws_ce_anomaly_subscription" "service" {
  name             = local.name
  frequency        = "IMMEDIATE"
  monitor_arn_list = [aws_ce_anomaly_monitor.service.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.cost_alerts.arn
  }

  # Alert when an anomaly's total impact reaches 50 USD.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["50"]
    }
  }

  depends_on = [aws_sns_topic_policy.cost_alerts]
}
