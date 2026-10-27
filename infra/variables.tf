variable "region" {
  description = "AWS Region for the service."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "team" {
  description = "Team that owns the service and pays for it."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.team))
    error_message = "team must be lowercase letters, digits and hyphens, for example payments."
  }
}

variable "service" {
  description = "Logical service name, the unit you report costs for."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.service))
    error_message = "service must be lowercase letters, digits and hyphens, for example checkout."
  }
}

variable "cost_center" {
  description = "Finance cost center that the spend is charged to."
  type        = string

  validation {
    condition     = can(regex("^cc-[0-9]{4}$", var.cost_center))
    error_message = "cost_center must look like cc-1042."
  }
}

variable "owner" {
  description = "Email address of the person or group to ask about these resources."
  type        = string

  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[a-z]{2,}$", var.owner))
    error_message = "owner must be an email address, for example payments-oncall@example.com."
  }
}

variable "ami_id" {
  description = "AMI for the application servers (arm64, because the default sizes are Graviton)."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnets for the Auto Scaling group."
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "Existing DB subnet group for the database."
  type        = string
}

variable "instance_type" {
  description = "Optional override for the environment's default instance type."
  type        = string
  default     = null
}

variable "monthly_budget_usd" {
  description = "Monthly budget for this service in this environment, in USD."
  type        = number
}

variable "alert_email" {
  description = "Email address that receives budget and anomaly alerts."
  type        = string
}
