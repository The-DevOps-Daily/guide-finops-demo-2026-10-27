terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.8"
    }
  }
}

variable "billing_account" {
  description = "Billing account ID, for example 012345-6789AB-CDEF01."
  type        = string
}

variable "project_number" {
  description = "Number of the project that runs checkout in dev."
  type        = string
}

variable "notification_channels" {
  description = "Cloud Monitoring notification channels for the alerts."
  type        = list(string)
}

resource "google_billing_budget" "checkout_dev" {
  billing_account = var.billing_account
  display_name    = "checkout-dev-monthly"

  budget_filter {
    projects        = ["projects/${var.project_number}"]
    labels          = { service = "checkout" }
    calendar_period = "MONTH"
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = "150"
    }
  }

  threshold_rules {
    threshold_percent = 0.8
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "FORECASTED_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
  }
}
