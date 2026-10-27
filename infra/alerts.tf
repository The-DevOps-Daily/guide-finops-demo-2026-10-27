resource "aws_sns_topic" "cost_alerts" {
  name = "${local.name}-cost-alerts"
}

# AWS Budgets publishes to the topic, for this account only.
data "aws_iam_policy_document" "cost_alerts" {
  statement {
    sid       = "AllowBudgetsToPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.cost_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
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

  # Budgets must be allowed to publish before it sends to the topic.
  depends_on = [aws_sns_topic_policy.cost_alerts]
}
