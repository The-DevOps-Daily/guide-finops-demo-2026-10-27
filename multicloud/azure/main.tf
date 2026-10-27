terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.11"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Subscription that runs the checkout service."
  type        = string
}

resource "azurerm_consumption_budget_subscription" "checkout_dev" {
  name            = "checkout-dev-monthly"
  subscription_id = "/subscriptions/${var.subscription_id}"
  amount          = 150
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-11-01T00:00:00Z"
  }

  filter {
    tag {
      name   = "service"
      values = ["checkout"]
    }
    tag {
      name   = "environment"
      values = ["dev"]
    }
  }

  notification {
    enabled        = true
    threshold      = 100
    threshold_type = "Forecasted"
    operator       = "GreaterThan"
    contact_emails = ["payments-oncall@example.com"]
  }

  notification {
    enabled        = true
    threshold      = 80
    threshold_type = "Actual"
    operator       = "GreaterThan"
    contact_emails = ["payments-oncall@example.com"]
  }
}
