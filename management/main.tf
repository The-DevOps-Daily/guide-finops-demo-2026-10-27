# Apply in the management (payer) account of the AWS organization: cost
# allocation tags and tag-based anomaly monitors can only be managed there.

provider "aws" {
  region = "us-east-1"
}

variable "alert_email" {
  description = "Email address that receives anomaly alerts for checkout."
  type        = string
}

# Billing ignores resource tags until they are activated for cost allocation.
resource "aws_ce_cost_allocation_tag" "cost_tags" {
  for_each = toset(["team", "service", "environment", "cost-center", "owner"])

  tag_key = each.value
  status  = "Active"
}

resource "aws_sns_topic" "checkout_anomalies" {
  name = "checkout-cost-anomalies"
}

# Cost Anomaly Detection publishes to the topic, for this account only.
data "aws_iam_policy_document" "checkout_anomalies" {
  statement {
    sid       = "AllowAnomalyDetectionToPublish"
    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.checkout_anomalies.arn]

    principals {
      type        = "Service"
      identifiers = ["costalerts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [split(":", aws_sns_topic.checkout_anomalies.arn)[4]]
    }
  }
}

resource "aws_sns_topic_policy" "checkout_anomalies" {
  arn    = aws_sns_topic.checkout_anomalies.arn
  policy = data.aws_iam_policy_document.checkout_anomalies.json
}

resource "aws_sns_topic_subscription" "checkout_anomalies_email" {
  topic_arn = aws_sns_topic.checkout_anomalies.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# A customer managed monitor for the costs tagged service=checkout, in
# every account and environment. The null keys follow the provider's
# documented example for custom monitors.
resource "aws_ce_anomaly_monitor" "checkout" {
  name         = "checkout"
  monitor_type = "CUSTOM"

  depends_on = [aws_ce_cost_allocation_tag.cost_tags]

  monitor_specification = jsonencode({
    And            = null
    CostCategories = null
    Dimensions     = null
    Not            = null
    Or             = null
    Tags = {
      Key          = "service"
      MatchOptions = null
      Values       = ["checkout"]
    }
  })
}

resource "aws_ce_anomaly_subscription" "checkout" {
  name             = "checkout"
  frequency        = "IMMEDIATE"
  monitor_arn_list = [aws_ce_anomaly_monitor.checkout.arn]

  subscriber {
    type    = "SNS"
    address = aws_sns_topic.checkout_anomalies.arn
  }

  # Alert when an anomaly's total impact reaches 50 USD.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["50"]
    }
  }

  depends_on = [aws_sns_topic_policy.checkout_anomalies]
}
